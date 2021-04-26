USE [MonitorDB]
GO
/****** Object:  StoredProcedure [dbo].[ap_climax]    Script Date: 26/04/2021 17:27:21 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[ap_climax] @task_no integer
AS
BEGIN
BEGIN TRY

PRINT 'VERSION 1.2.1'	
	
	/*
	VERSION 1.2.1
	
	Algoritmo buscar en m_signal_processed las tramas que entraron por las task xxxx y revisar si su correspondiente
	aux2 con el evento definido, en event_history está vacío, en el caso de estarlo, completar según algoritmo de parseo.
	12/04/2021 se agrega Control de task disabled para que termine el ciclo si task deshabilitada.
	Se agrega update task_status cuando entra por el catch, para que si entra por catch miestre error más rápido, y no se ponga normal hasta que esté arreglado el problema.
	Se agrega control que si no están creadas las variables de la tabla options, se agreguen.
	intenta cargar las configs del task_option, en caso de que alguna sea null, se asignará una por default
	Si se le pasa parámetro 12345678 sirve para ver los settings que carga
	Bug corregido: Bug corregido 26/04/2021 (and option_id like 'CLIMAX_%'), para que permita mas de 9 task_option
	*/
	
/*INICIO -> INICIALIZACIÓN DE SETTINGS*/

/*serán los seqno del event_history que cumplan la condición*/

set nocount on;




declare @events_seqs_no as table (event_seqno numeric(18,0),aux2 varchar(max))
declare @image_events as table (event_id varchar(10))
declare @tasks_no as table (task_no integer)
declare @CLIMAX_MINUTES_BEFORE as integer
--ejemplo packet sender S011[#8888|NBA*'<LINK>http://10.24.34.23:8899/capture_event/media/35000009/2021-02-11/2021-02-11_124646_39_06/35000009_012a3930_2021-02-11_134646_006.jpg<LINK/>']    <6>
declare @seqno as numeric(18,0)
declare @raw_message as varchar(max)
declare @link as varchar(max)
declare @CLIMAX_MAS_PREFIX as varchar(max)
declare @linkcompleto as varchar(max)
declare @pipe as varchar(1)
declare @barra as varchar(1)
declare @CLIMAX_START_URL_TAG as varchar(max)
declare @CLIMAX_END_URL_TAG as varchar(max)
declare @CLIMAX_HTTP_SERVER_URL as varchar (max)
declare @CLIMAX_DELAY_TIME as varchar(12)
declare @CLIMAX_MAX_ROW_PROCESSING as integer
declare @thisTask as integer /*Sirve para manejar el estado de esta task*/
declare @lastSignal as dateTime /*Probar para poner el la ultima señal recibida de Climax*/
declare @flag_salida as integer
declare @enable_flag as varchar(1)
declare @spid as integer
declare @CLIMAX_IMAGE_EVENTS as varchar(max)
declare @CLIMAX_IMAGE_EVENTS_aux as varchar(max)
declare @CLIMAX_TASK_MONITORING as varchar(max)
declare @CLIMAX_TASK_MONITORING_aux as varchar(max)
declare @largo_palabra as integer
declare @imageeventsXml xml
declare @tasks_noXml xml
declare @elementos_de_tasks_no as integer
declare @elementos_de_image_events as integer
declare @taskOptionElements as integer
declare @rcvrtyp_id as varchar(max)
-- Es para propósito de test, si quieres testear como se comportaría y que variables tiene cargadas, se le pasa el nro de la task pero negativo
if @task_no < 0 
begin
set @thisTask=isnull(@task_no*-1,10000);
end 
else 
begin
set @thisTask=isnull(@task_no,10000);
end


/*INICIO SETTINGS EN TABLA OPTIONS DE DONDE TASK OPTION TOMARÁ VALORES*/
DECLARE @CANTIDAD_VARIABLES_CLIMAX_AP_CLIMAX INTEGER
SELECT @CANTIDAD_VARIABLES_CLIMAX_AP_CLIMAX=COUNT(1) FROM options WHERE 
(OPTION_ID='CLIMAX_DELAY_TIME' OR
OPTION_ID='CLIMAX_END_URL_TAG' OR
OPTION_ID='CLIMAX_HTTP_SERVER_URL' OR
OPTION_ID='CLIMAX_IMAGE_EVENTS' OR
OPTION_ID='CLIMAX_MAS_PREFIX' OR
OPTION_ID='CLIMAX_MAX_ROW_PROCESSING' OR
OPTION_ID='CLIMAX_MINUTES_BEFORE' OR
OPTION_ID='CLIMAX_START_URL_TAG' OR
OPTION_ID='CLIMAX_TASK_MONITORING')
IF (@CANTIDAD_VARIABLES_CLIMAX_AP_CLIMAX<>9)
BEGIN
DELETE options WHERE OPTION_ID LIKE 'CLIMAX_%'AND option_id<>'climax_video_url'
INSERT INTO OPTIONS VALUES
('CLIMAX_DELAY_TIME','CLIMAX_DELAY_TIME',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_END_URL_TAG','CLIMAX_END_URL_TAG',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_HTTP_SERVER_URL','CLIMAX_HTTP_SERVER_URL',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_IMAGE_EVENTS','CLIMAX_IMAGE_EVENTS',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_MAS_PREFIX','CLIMAX_MAS_PREFIX',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_MAX_ROW_PROCESSING','CLIMAX_MAX_ROW_PROCESSING',1,GETDATE(),'N',NULL,NULL,'N','N','T',NULL,'N','Y'),
('CLIMAX_MINUTES_BEFORE','CLIMAX_MINUTES_BEFORE',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_START_URL_TAG','CLIMAX_START_URL_TAG',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_TASK_MONITORING','CLIMAX_TASK_MONITORING',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y')
PRINT 'TABLA OPTIONS SETEADA'
END
ELSE
BEGIN
PRINT 'NADA PARA SETEAR EN OPTIONS ESTÁN SUS 9 VARIABLES' 
END
/*FIN SETTINGS EN TABLA OPTIONS DE DONDE TASK OPTION TOMARÁ VALORES*/
-- intenta cargar las configs del task_option, 
SELECT @CLIMAX_DELAY_TIME=option_value from M_TASK_OPTION with(nolock)where option_id='CLIMAX_DELAY_TIME' and task_no=@thisTask
SELECT @CLIMAX_HTTP_SERVER_URL=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_HTTP_SERVER_URL' and task_no=@thisTask
SELECT @CLIMAX_MAS_PREFIX=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MAS_PREFIX' and task_no=@thisTask
SELECT @CLIMAX_MAX_ROW_PROCESSING=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MAX_ROW_PROCESSING' and task_no=@thisTask
SELECT @CLIMAX_MINUTES_BEFORE=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MINUTES_BEFORE' and task_no=@thisTask
SELECT @CLIMAX_START_URL_TAG=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_START_URL_TAG' and task_no=@thisTask
SELECT @CLIMAX_END_URL_TAG=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_END_URL_TAG' and task_no=@thisTask
SELECT @CLIMAX_IMAGE_EVENTS=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_IMAGE_EVENTS' and task_no=@thisTask



-- en caso de que alguna sea null, se asignará una por default

IF LEN(@CLIMAX_IMAGE_EVENTS)>0
BEGIN
WHILE(LEN(@CLIMAX_IMAGE_EVENTS)>0)
BEGIN
	IF CHARINDEX(',',@CLIMAX_IMAGE_EVENTS)<>0 
	BEGIN 
	--PRINT 'HAY MAS DE UNO'
	--'123,4567,89'
	--Insertar el primero
	insert into @image_events values (SUBSTRING(@CLIMAX_IMAGE_EVENTS,0,CHARINDEX(',',@CLIMAX_IMAGE_EVENTS)))
	
	set @largo_palabra=len(SUBSTRING(@CLIMAX_IMAGE_EVENTS,0,CHARINDEX(',',@CLIMAX_IMAGE_EVENTS)))	
	set @CLIMAX_IMAGE_EVENTS_aux=SUBSTRING(@CLIMAX_IMAGE_EVENTS,@largo_palabra+2,len(@CLIMAX_IMAGE_EVENTS)-@largo_palabra+1)
	--insert into @image_events values (
	SET @CLIMAX_IMAGE_EVENTS=@CLIMAX_IMAGE_EVENTS_aux
	
	
	END
		ELSE 
		BEGIN
		--PRINT 'HAY SOLO UN EVENTO'
		insert into @image_events values (@CLIMAX_IMAGE_EVENTS)
		SET @CLIMAX_IMAGE_EVENTS='';
		END 
END
END --WHILE
ELSE
BEGIN
PRINT 'LISTA DE EVENTOS VACIA, SE CARGARÁ POR DEFAULT SEGUN DETALLE DE ABAJO'
END


SELECT @CLIMAX_TASK_MONITORING=option_value from M_TASK_OPTION where option_id='CLIMAX_TASK_MONITORING' and task_no=@thisTask

IF LEN(@CLIMAX_TASK_MONITORING)>0
BEGIN
WHILE(LEN(@CLIMAX_TASK_MONITORING)>0)
BEGIN
	IF CHARINDEX(',',@CLIMAX_TASK_MONITORING)<>0 
	BEGIN 
	--PRINT 'HAY MAS DE UNO'
	
	--Insertar el primero
	insert into @tasks_no values (SUBSTRING(@CLIMAX_TASK_MONITORING,0,CHARINDEX(',',@CLIMAX_TASK_MONITORING)))
	
	set @largo_palabra=len(SUBSTRING(@CLIMAX_TASK_MONITORING,0,CHARINDEX(',',@CLIMAX_TASK_MONITORING)))	
	set @CLIMAX_TASK_MONITORING_aux=SUBSTRING(@CLIMAX_TASK_MONITORING,@largo_palabra+2,len(@CLIMAX_TASK_MONITORING)-@largo_palabra+1)
	--insert into @image_events values (
	SET @CLIMAX_TASK_MONITORING=@CLIMAX_TASK_MONITORING_aux
	
	
	END
		ELSE 
		BEGIN
	--	PRINT 'HAY SOLO UN EVENTO'
		insert into @tasks_no values (@CLIMAX_TASK_MONITORING)
		SET @CLIMAX_TASK_MONITORING='';
		END 
END
END --WHILE
ELSE
BEGIN
PRINT 'TAREAS CLIMAX VACIO, SE CARGARÁ POR DEFAULT SEGUN DETALLE DE ABAJO'
END


set @elementos_de_tasks_no=(select count(1) from @tasks_no)
set @elementos_de_image_events=(select count(1) from @image_events)

set @flag_salida=1;
set @lastSignal=GETDATE()


/*CHEQUEO, SI NO TIENE LAS TASK_OPTION CARGADAS LA TASK, CARGAR*/
set @taskOptionElements=(select count(1) from m_task_option where task_no=@thisTask and option_id like 'CLIMAX_%')  
--Bug corregido 26/04/2021 (and option_id like 'CLIMAX_%')
set @rcvrtyp_id=(select rcvrtyp_id  from m_task where task_no=@thisTask)

IF(@rcvrtyp_id='CXLINK')
BEGIN
	IF (@taskOptionElements=0)
	BEGIN
	insert into m_task_option values
	(@thisTask,'CLIMAX_DELAY_TIME',getdate(),1,'00:00:05:000'),
	(@thisTask,'CLIMAX_HTTP_SERVER_URL',getdate(),1,'http://10.24.34.23/index.php?uri='),
	(@thisTask,'CLIMAX_IMAGE_EVENTS',getdate(),1,'CXLINK'),
	(@thisTask,'CLIMAX_MAS_PREFIX',getdate(),1,'VF|MAS|'),
	(@thisTask,'CLIMAX_MAX_ROW_PROCESSING',getdate(),1,'200'),
	(@thisTask,'CLIMAX_MINUTES_BEFORE',getdate(),1,'60'),
	(@thisTask,'CLIMAX_START_URL_TAG',getdate(),1,'<LINK>'),
	(@thisTask,'CLIMAX_END_URL_TAG',getdate(),1,'<LINK/>'),
	(@thisTask,'CLIMAX_TASK_MONITORING',getdate(),1,'29,229,284')
	END
	ELSE IF(@taskOptionElements<>9 AND @taskOptionElements<>0)
	BEGIN
	PRINT 'COLOQUE TASK_OPTIONS (9) O DEJE SIN TASK_OPTIONS ASÍ SE CARGA POR DEFAULT'
				UPDATE m_task_current_status
				SET last_status_date = GETDATE(), taskstat_no = 4,
						last_error_msg = 'COMPLETE TASK_OPTIONS OR LEAVE EMPTY FOR AUTO COMPLETE',last_signal_date=@lastSignal,last_status='SEE.RECVTP'
				WHERE task_no = @thisTask AND enable_flag = 'Y'
				
				RETURN
	END
END
ELSE
BEGIN
PRINT 'COLOQUE EL RECEIVER TYPE "CXLINK" EN LA TASK'
UPDATE m_task_current_status
				SET last_status_date = GETDATE(), taskstat_no = 4,
						last_error_msg = 'PLEASE SET "CXLINK" RECEIVER TYPE ON TASK',last_signal_date=@lastSignal,last_status='SEE.RECVTP'
				WHERE task_no = @thisTask AND enable_flag = 'Y'
				--print 'Actualizo Estado de la TASK'
				RETURN
END



set @pipe='|'
set @barra='//'

/*IMPRIMIR SETTINGS */


set @imageeventsXml=(select * from @image_events FOR XML PATH(''))

set @tasks_noXml=(select * from @tasks_no FOR XML PATH(''))
PRINT '@CLIMAX_DELAY_TIME '+CONVERT(VARCHAR(MAX),@CLIMAX_DELAY_TIME)
PRINT '@CLIMAX_HTTP_SERVER_URL '+CONVERT(VARCHAR(MAX),@CLIMAX_HTTP_SERVER_URL)
PRINT '@CLIMAX_MAS_PREFIX '+CONVERT(VARCHAR(MAX),@CLIMAX_MAS_PREFIX)
PRINT '@CLIMAX_MAX_ROW_PROCESSING '+CONVERT(VARCHAR(MAX),@CLIMAX_MAX_ROW_PROCESSING)
PRINT '@CLIMAX_START_URL_TAG '+CONVERT(VARCHAR(MAX),@CLIMAX_START_URL_TAG)
PRINT '@CLIMAX_END_URL_TAG '+CONVERT(VARCHAR(MAX),@CLIMAX_END_URL_TAG)
PRINT '@CLIMAX_MINUTES_BEFORE '+CONVERT(VARCHAR(MAX),@CLIMAX_MINUTES_BEFORE)
PRINT '@CLIMAX_IMAGE_EVENTS '+CONVERT(VARCHAR(MAX),@imageeventsXml)
PRINT '@CLIMAX_TASK_MONITORING '+CONVERT(VARCHAR(MAX),@tasks_noXml)

/*FIN -> INICIALIZACIÓN DE SETTINGS*/
-- Si es test termina acá,es decir si es la task pero valor negativo, es para ver las variables inicializadas
if @task_no < 0 return










while (@flag_salida=1)

begin
/*Cargando los seqno que hay que tratar*/

/*inicio si la task está disabled salir y matar proceso*/
select @enable_flag=enable_flag,@spid=spid from m_task_current_status with(nolock)
where task_no=@thisTask

if (@enable_flag='N')
begin
PRINT 'TAREA DESHABILITADA SALIENDO'
set @flag_salida=0 -- Se pone en false la condición del while y termina programa
RETURN
--set @SQL='KILL ' + CAST(@SPID as varchar(max))
--EXEC (@SQL)
end
/*FIN si la task está disabled salir y matar proceso*/







insert into @events_seqs_no
select top (@CLIMAX_MAX_ROW_PROCESSING) msp.event_seqno,ev.aux2  from m_signal_processed msp with(nolock)
inner join event_history ev on ev.seqno=msp.event_seqno
where 
msp.recv_date > DATEADD(MINUTE,-@CLIMAX_MINUTES_BEFORE,GETDATE()) and --respetando a partir de cuando
msp.task_no in (select task_no from @tasks_no) and -- que las tareas sean de climax
ev.event_id in (select event_id from @image_events) -- que pertenezca a el o los eventos que traigan la url de imagen
AND
(ev.aux2 not like 'VF|MAS|http%' -- y que el url no esté puesta en el aux2 de event_history
OR 
ev.aux2 is null)
and msp.raw_message like '%'+@CLIMAX_END_URL_TAG+'%'
order by msp.event_seqno asc 



if(@@ROWCOUNT=0)
begin

print 'Nada para procesar'
end
else
begin
print 'Estoy ocupado'


declare seqno_index cursor local for select event_seqno from @events_seqs_no
open seqno_index
fetch next from seqno_index into @seqno
WHILE @@FETCH_STATUS = 0
BEGIN
			
			select @raw_message=raw_message,@lastSignal=recv_date from m_signal_processed 
			with(nolock) where event_seqno=@seqno

			set @link=SUBSTRING(@raw_message,CHARINDEX(@CLIMAX_START_URL_TAG,@raw_message)+LEN(@CLIMAX_START_URL_TAG),CHARINDEX(@CLIMAX_END_URL_TAG,@raw_message)-CHARINDEX(@CLIMAX_START_URL_TAG,@raw_message)-LEN(@CLIMAX_START_URL_TAG))
			set @linkcompleto=@CLIMAX_MAS_PREFIX+@CLIMAX_HTTP_SERVER_URL+@link+@barra+@pipe
			
			UPDATE event_history SET aux2=@linkcompleto WHERE seqno=@seqno
			PRINT 'ACTUALIZANDO SEQNO '+CONVERT(VARCHAR(MAX),@seqno)+' EN EVENT_HISTORY' 
			print @linkcompleto
			
			
			
			
			fetch next from seqno_index into @seqno
END

CLOSE seqno_index
DEALLOCATE seqno_index

print 'salgo del cursor'

end
--select * from @events_seqs_no
/*Ponemos la task de MAS en Normal*/

UPDATE m_task_current_status
				SET last_status_date = GETDATE(), taskstat_no = 1,
						last_error_msg = 'Normal',last_signal_date=@lastSignal,last_status=null
				WHERE task_no = @thisTask AND enable_flag = 'Y'
				print 'Actualizo Estado de la TASK'
				
WAITFOR DELAY @CLIMAX_DELAY_TIME


END-- FIN WHILE

END TRY


BEGIN CATCH
UPDATE m_task_current_status
				SET last_status_date = GETDATE(), taskstat_no = 3,
						last_error_msg = 'Process Error',last_signal_date=@lastSignal,last_status='T'
				WHERE task_no = @thisTask AND enable_flag = 'Y'
				print 'Actualizo Estado de la TASK'
				
				print 'ERROR NRO '+CONVERT(VARCHAR(MAX),@@error)+' LINEA '+ CONVERT(VARCHAR(MAX),ERROR_LINE())+' '+ ERROR_MESSAGE()+' EN EL SP -> '+ ERROR_PROCEDURE()
WAITFOR DELAY @CLIMAX_DELAY_TIME
	
				
END CATCH

END


