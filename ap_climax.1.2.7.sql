USE [MonitorDB]
GO
/****** Object:  StoredProcedure [dbo].[ap_climax]    Script Date: 27/09/2021 4:41:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ap_climax -1000
--ap_climax 231
ALTER PROCEDURE [dbo].[ap_climax] @task_no integer
AS
BEGIN
BEGIN TRY

PRINT 'VERSION 1.2.7'	
	
	/*
	VERSION 1.2.2
	
	Algoritmo buscar en m_signal_processed las tramas que entraron por las task xxxx y revisar si su correspondiente
	aux2 con el evento definido, en event_history está vacío, en el caso de estarlo, completar según algoritmo de parseo.
	12/04/2021 se agrega Control de task disabled para que termine el ciclo si task deshabilitada.
	Se agrega update task_status cuando entra por el catch, para que si entra por catch miestre error más rápido, y no se ponga normal hasta que esté arreglado el problema.
	Se agrega control que si no están creadas las variables de la tabla options, se agreguen.
	intenta cargar las configs del task_option, en caso de que alguna sea null, se asignará una por default
	Si se le pasa parámetro 12345678 sirve para ver los settings que carga
	Bug corregido: Bug corregido 26/04/2021 (and option_id like 'CLIMAX_%'), para que permita mas de 9 task_option
	VERSION 1.2.3 
	Se agrega control de que solo actualice cuando el server_id corresponde al servidor actualizante,
	para así evitar escribir en seqno repetido cuando hay más de un grupo, como es el caso de España.
	VERSION 1.2.4 Se corrije bug, que reprocesaba los eventos, sobreescribiendo con url de otros contratos.
	delete @events_seqs_no --19/08/2021 al no borrar la variable tabla @events_seqs_no y el proceso, como nunca se reinicia en el tiempo, se acumulaban @seqno
-- y los volvía a procesar con el valor de LinkCompleto que como nunca trae null, siempre queda con el último link generado.
-- Entonces si reprocesa, 2000 seqno viejos, que ya no existen en m_signal_processed, les pone el mismo valor, hasta que aparece el seqno que si existe en ambas tablas, 
-- y actualiza el link completo. por eso es necesario que con cada "procesamiento" la tabla arranque limpia al igual que la variable @linkCompleto.
-- El el comportamiento análogo a inicializar una variable con null.
-- vaciar variable 
			set @linkcompleto=null --19/08/2021

	VERSION 1.2.5 En esta versión en vez de actualizar el evento correspondiente en event_history colocando el link en aux2, se utlizará
	el stored procedure de utc ap_manual_signal para insertar un evento @CLIMAX_MASKED_EVENT, y que en el cuerpo del mensaje lleve la url clickeable 
	por el usuario.
	De esa manera al insertar un evento @CLIMAX_MASKED_EVENT, este replique por redundancia.
	Se quita option_id CLIMAX_MAS_PEFIX y se agrega CLIMAX_MASKED_EVENT

 Modo de uso de ejemplo usado en Smart:
 exec dbo.ap_manual_signal N'C123456' -- Cód connexion 
,NULL --log_date (siempre null) ,
N'SMPAN' – evento (para pánico usar SMPAN ,
N'A' --estado zona (para pánico usar A) ,
N'600' –Zona (usar zona virtual 600) ,
N'SMART' --ID Usuario, máx 6 caracteres (poner SMART para ver claro el origen) ,
N'US# FRAN5678901234567890@PROSEGUR.COM LOC# 40.453266 -3.6942988' --Comentario. Por ej. usuario que lo ha generado + localización. Max 255
,N'N' --log_only. Siempre 'N'
,N'Y' --recurse_flag. Siempre 'Y'
,0 --debug. Siempre 0
,100004 --ID Empleado que inserta. Por ejemplo 100004
exec dbo.ap_manual_signal N'C123456',NULL,N'SMPAN',N'A',N'600',N'SMART',N'US# FRAN5678901234567890@PROSEGUR.COM LOC# 40.453266 -3.6942988' ,N'N',N'Y',0,100004
	VERSION 1.2.6
	Se deja andando la opción de que actualice el event histoty con prefijo VF para que siga apareciendo el ícono de la cámara, a la vez que se envía el evento manual
	el objetivo que se persigue es la transición tranquila con Smart.
	Se define que, si el prefijo es NOT_USE en la variable @CLIMAX_MAS_PREFIX, entonces, la funcionalidad de actualizar event_history con la
	url generadora de icono y link, desaparezca, aunque se debe seguir marcando con VF, para que se reconozca como registro procesado.
	
	
	VERSIÒN 1.2.7 
	Se cambia la lògica de CLIMAX_MAS_PREFIX para que solo pueda tomar valor "Y" O "N" (SIN COMILLAS)
	El objetivo es simplificar el setting, si el input es Y, completar con VF.. para mostrar ícono de cámara en event_history y si el valor es otra cosa o nulo
	no generarà el ìcono de la càmara.
	Se inserta el seqno del evento procesado dentro del comment del nuevo evento generado con ap_manual_signal (MASKED_EVENT),
	para así poder llevar registro en memoria, de cuál fue el último seqno procesado.
	La primera vez indefectiblemente tiene que consultar a Event_history el ultimo seqno procesado, luego por performance, almacena ese valor en memoria.
	Y para saber si fue procesado, busca en el último MASKED_EVENT, que si no existe en el tiempo definido por la variable
	MINUTES_BEHIND, lo setea vacío, y procesa todo lo que esté mayor a  esos minutos seteados en la task option.
	Se agrega funcionalidad para reinicio de la task desde Master.
	La mejora hace que al cambiar de pasivo a activo, no se reprocesen eventos.

	
	
	
	*/
	
/*INICIO -> INICIALIZACIÓN DE SETTINGS*/

/*serán los seqno del event_history que cumplan la condición*/

set nocount on;



declare @server_id as varchar(1) --v_1.2.3
set @server_id=(select server_id  from monitor_server with(nolock) where servername=@@SERVERNAME)
declare @events_seqs_no as table (event_seqno numeric(18,0),aux2 varchar(max))
declare @image_events as table (event_id varchar(10))
declare @tasks_no as table (task_no integer)
declare @CLIMAX_MINUTES_BEFORE as integer
--ejemplo packet sender S011[#8888|NBA*'<LINK>http://10.24.34.23:8899/capture_event/media/35000009/2021-02-11/2021-02-11_124646_39_06/35000009_012a3930_2021-02-11_134646_006.jpg<LINK/>']    <6>
declare @seqno as numeric(18,0)
declare @last_msignal_processed_seqno as numeric(18,0) --1.2.7
declare @last_masked_event_hist_processed_seqno as numeric(18,0) --1.2.7
declare @raw_message as varchar(max)
declare @zone_start_tag as varchar(max) --1.2.5
declare @zone_end_tag as varchar(max)--1.2.5
declare @link as varchar(max)
declare @CLIMAX_MAS_PREFIX as varchar(max) --1.2.6 Se pide de nuevo para dar tiempo a smart al cambio
declare @linkcompleto as varchar(max)
declare @linkams as varchar(max)
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
declare @CLIMAX_MASKED_EVENT as varchar(max) --1.2.5 
declare @largo_palabra as integer
declare @imageeventsXml xml
declare @tasks_noXml xml
declare @elementos_de_tasks_no as integer
declare @elementos_de_image_events as integer
declare @taskOptionElements as integer
declare @rcvrtyp_id as varchar(max)
declare @ipReceptora varchar(max)--26/04/2021
declare @puertoImagenReceptora varchar(max)--26/04/2021
declare @comienzoUrl as varchar(max)--26/04/2021
declare @task_options_count as integer
set @task_options_count=10 --1.2.6 es para el control inicial, de manera que si no están todas, se autocargue.
--1/9/2021 1.2.5
/*Variables obligatorias de ap_manual_signal*/
declare @ams_cs_no	as varchar(20) 
declare @ams_log_date as datetime 
declare @ams_event_id as char(6) 
declare @ams_zonestate_id as char(4) 
declare @ams_zone as char(6) 
declare @ams_user as char(6) 
declare @ams_comment as	varchar(255) 
declare @ams_log_only as char(1) 
declare @ams_recurse_flag as char(1)
declare @ams_debug as int 
declare @ams_emp_no	as int

/*1.2.7 variables para identificar el ultimo procesado*/
declare @startSeqnoTag as varchar(max)
declare @endSeqnoTag as varchar(max)
set @startSeqnoTag='<@seqno>'
set @endSeqnoTag='</@seqno>'
DECLARE @COMMENT AS VARCHAR(max)--1.2.7
declare @registrosTabla as varchar(max)--1.2.7
/*Variables para determinar la zona en función del rawmessage*/-- 1.2.5
set @zone_start_tag='|N'
set @zone_end_tag='*'''

/*set de variables fijas ap_manual_signal por def de doc "Inserción de eventos desde la plataforma Smart en MAStermind"*/
set @ams_cs_no=null -- valor inicial, mas abajo se setea el correcto
set @ams_log_date=null
set @ams_event_id='CLNK' 
set @ams_zonestate_id='A' 
set @ams_zone='600' 
set @ams_user='CLIMAX' 
set @ams_comment=NULL -- IRÁ LA URL FORMATEADA
set @ams_log_only='N'
set @ams_recurse_flag='Y'
set @ams_debug=0 
set @ams_emp_no=1 -- MAS



set @comienzoUrl='://'--26/04/2021
set @puertoImagenReceptora='8899'--26/04/2021

set @puertoImagenReceptora=':'+@puertoImagenReceptora--26/04/2021
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
OPTION_ID='CLIMAX_MAS_PREFIX' OR --1.2.6
OPTION_ID='CLIMAX_MAX_ROW_PROCESSING' OR
OPTION_ID='CLIMAX_MINUTES_BEFORE' OR
OPTION_ID='CLIMAX_START_URL_TAG' OR
OPTION_ID='CLIMAX_TASK_MONITORING' OR
OPTION_ID='CLIMAX_MASKED_EVENT') -- 1.2.5
IF (@CANTIDAD_VARIABLES_CLIMAX_AP_CLIMAX<>@task_options_count)--1.2.6
BEGIN
DELETE options WHERE OPTION_ID LIKE 'CLIMAX_%'AND option_id<>'climax_video_url'
INSERT INTO OPTIONS VALUES
('CLIMAX_DELAY_TIME','CLIMAX_DELAY_TIME',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_END_URL_TAG','CLIMAX_END_URL_TAG',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_HTTP_SERVER_URL','CLIMAX_HTTP_SERVER_URL',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_IMAGE_EVENTS','CLIMAX_IMAGE_EVENTS',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_MAS_PREFIX','CLIMAX_MAS_PREFIX',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'), --1.2.6
('CLIMAX_MAX_ROW_PROCESSING','CLIMAX_MAX_ROW_PROCESSING',1,GETDATE(),'N',NULL,NULL,'N','N','T',NULL,'N','Y'),
('CLIMAX_MINUTES_BEFORE','CLIMAX_MINUTES_BEFORE',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_START_URL_TAG','CLIMAX_START_URL_TAG',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_TASK_MONITORING','CLIMAX_TASK_MONITORING',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y'),
('CLIMAX_MASKED_EVENT','CLIMAX_MASKED_EVENT',1,GETDATE(),'N',NULL,NULL,NULL,'N','T',NULL,'N','Y')
PRINT 'TABLA OPTIONS SETEADA'
END
ELSE
BEGIN
PRINT 'NADA PARA SETEAR EN TABLA OPTIONS ESTÁN SUS '+convert(varchar(3),@task_options_count)+' VARIABLES POSIBLES' 
END
/*FIN SETTINGS EN TABLA OPTIONS DE DONDE TASK OPTION TOMARÁ VALORES*/
-- intenta cargar las configs del task_option, 
SELECT @CLIMAX_DELAY_TIME=option_value from M_TASK_OPTION with(nolock)where option_id='CLIMAX_DELAY_TIME' and task_no=@thisTask
SELECT @CLIMAX_HTTP_SERVER_URL=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_HTTP_SERVER_URL' and task_no=@thisTask
IF(LEN(ISNULL(@CLIMAX_HTTP_SERVER_URL,''))=0)--SI NO TIENE UN VALOR CARGADO, ES NULL O VACIO ENTONCES SE LLENA POR DEFAULT 26/04/2021
BEGIN
SET @CLIMAX_HTTP_SERVER_URL='http://RECEIVER_IP/index.php?uri='
/*RECEIVER_IP, se usará ára hacer un replace luego, si es que no hay cargado una url en el task option*/
END
SELECT @CLIMAX_MAS_PREFIX=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MAS_PREFIX' and task_no=@thisTask-- 1.2.6
SELECT @CLIMAX_MAX_ROW_PROCESSING=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MAX_ROW_PROCESSING' and task_no=@thisTask
SELECT @CLIMAX_MINUTES_BEFORE=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MINUTES_BEFORE' and task_no=@thisTask
SELECT @CLIMAX_START_URL_TAG=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_START_URL_TAG' and task_no=@thisTask
SELECT @CLIMAX_END_URL_TAG=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_END_URL_TAG' and task_no=@thisTask
SELECT @CLIMAX_IMAGE_EVENTS=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_IMAGE_EVENTS' and task_no=@thisTask
SELECT @CLIMAX_MASKED_EVENT=option_value from M_TASK_OPTION with(nolock) where option_id='CLIMAX_MASKED_EVENT' and task_no=@thisTask --1.2.5

set @ams_event_id=@CLIMAX_MASKED_EVENT --1.2.5




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
--Bug corregido 26/04/2021 (and option_id like 'CLIMAX_%'), al querer cargar mas de 9 task_option saltaba error por distinto de 9
set @rcvrtyp_id=(select rcvrtyp_id  from m_task where task_no=@thisTask)

IF(@rcvrtyp_id='CXLINK')
BEGIN
	IF (@taskOptionElements=0)
	BEGIN
	insert into m_task_option values
	(@thisTask,'CLIMAX_DELAY_TIME',getdate(),1,'00:00:05:000'),
	(@thisTask,'CLIMAX_HTTP_SERVER_URL',getdate(),1,@CLIMAX_HTTP_SERVER_URL),-- por default será SET @CLIMAX_HTTP_SERVER_URL='http://RECEIVER_IP/index.php?uri='
	(@thisTask,'CLIMAX_IMAGE_EVENTS',getdate(),1,'CXLINK'),
	(@thisTask,'CLIMAX_MAS_PREFIX',getdate(),1,'Y'), --1.2.6 para no usar, vacío o NOT_USE
	(@thisTask,'CLIMAX_MAX_ROW_PROCESSING',getdate(),1,'200'),
	(@thisTask,'CLIMAX_MINUTES_BEFORE',getdate(),1,'60'),
	(@thisTask,'CLIMAX_START_URL_TAG',getdate(),1,'<LINK>'),
	(@thisTask,'CLIMAX_END_URL_TAG',getdate(),1,'<LINK/>'),
	(@thisTask,'CLIMAX_TASK_MONITORING',getdate(),1,'10000'),--Para no crear un procesamiento inicial en task que tal vez existan ponemos nro alto.
	(@thisTask,'CLIMAX_MASKED_EVENT',getdate(),1,'CIMAGE')
	

	END
	ELSE IF(@taskOptionElements<>@task_options_count AND @taskOptionElements<>0 )
	BEGIN
	PRINT 'COLOQUE TASK_OPTIONS ('+CONVERT(varchar(3),@task_options_count)+') , SOLO COLOCÓ '+CONVERT(varchar(3),@taskOptionElements)+' ELEMENTOS, O DEJE SIN TASK_OPTIONS ASÍ SE CARGA POR DEFAULT'
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
PRINT '@CLIMAX_MAS_PREFIX '+CONVERT(VARCHAR(MAX),@CLIMAX_MAS_PREFIX)-- 1.2.6
PRINT '@CLIMAX_MAX_ROW_PROCESSING '+CONVERT(VARCHAR(MAX),@CLIMAX_MAX_ROW_PROCESSING)
PRINT '@CLIMAX_START_URL_TAG '+CONVERT(VARCHAR(MAX),@CLIMAX_START_URL_TAG)
PRINT '@CLIMAX_END_URL_TAG '+CONVERT(VARCHAR(MAX),@CLIMAX_END_URL_TAG)
PRINT '@CLIMAX_MINUTES_BEFORE '+CONVERT(VARCHAR(MAX),@CLIMAX_MINUTES_BEFORE)
PRINT '@CLIMAX_IMAGE_EVENTS '+CONVERT(VARCHAR(MAX),@imageeventsXml)
PRINT '@CLIMAX_TASK_MONITORING '+CONVERT(VARCHAR(MAX),@tasks_noXml)
PRINT '@CLIMAX_MASKED_EVENT '+CONVERT(VARCHAR(MAX),@CLIMAX_MASKED_EVENT)



/*FIN -> INICIALIZACIÓN DE SETTINGS*/
-- Si es test termina acá,es decir si es la task pero valor negativo, es para ver las variables inicializadas
if @task_no < 0 return


/*setear el último evento procesado para buscar a partir del siguiente en msignal_processed que sea mayor a este*/

SET @last_masked_event_hist_processed_seqno=(select max(seqno) from event_history
where event_id=@CLIMAX_MASKED_EVENT and event_date > DATEADD(MINUTE,-@CLIMAX_MINUTES_BEFORE,GETDATE()))--1.2.7
SET @COMMENT=(SELECT COMMENT FROM EVENT_HISTORY WHERE SEQNO=@last_masked_event_hist_processed_seqno)
SET @COMMENT=ISNULL(@COMMENT,'VACIO')


if(CHARINDEX(@startSeqnoTag,@COMMENT)=0 or @COMMENT='VACIO') --si en ese seqno, no estaba el start tag del seqno
begin
set @last_msignal_processed_seqno=0 --asumo primera vez que corre y asigno cero, para que procese esta version
end
else -- si está es porque  le inserté el seqno en el comment con ese tag
begin
set @last_msignal_processed_seqno=SUBSTRING(@COMMENT,CHARINDEX(@startSeqnoTag,@COMMENT)+ LEN(@startSeqnoTag),CHARINDEX(@endSeqnoTag,@COMMENT)-CHARINDEX(@startSeqnoTag,@COMMENT)-LEN(@startSeqnoTag))

end
print 'Ultimo seq_no procesado de m_signal_processed que tiene en el comment el string '+@startSeqnoTag+' es :'+convert(varchar(max),@last_msignal_processed_seqno)



while (@flag_salida=1)

begin
/*Cargando los seqno que hay que tratar*/

/*inicio si la task está disabled salir y matar proceso*/
select @enable_flag=enable_flag,@spid=spid from m_task_current_status with(nolock)
where task_no=@thisTask

if (@enable_flag='N')
begin
PRINT 'TAREA DESHABILITADA SALIENDO'
UPDATE m_task_current_status--1.2.7 Es para que master se dé cuenta de que el sp entendió mensaje de reinicio
				SET last_status_date = GETDATE(), taskstat_no = 3,
						last_error_msg = 'Shutdown',last_signal_date=@lastSignal,last_status=null
				WHERE task_no = @thisTask 
				print 'Actualizo Estado de la TASK'
set @flag_salida=0 -- Se pone en false la condición del while y termina programa
RETURN

end
/*FIN si la task está disabled salir y matar proceso*/





insert into @events_seqs_no
select top (@CLIMAX_MAX_ROW_PROCESSING) msp.event_seqno,'ev.aux2'/*corregir*/  from m_signal_processed msp with(nolock)
--inner join event_history ev on ev.seqno=msp.event_seqno
where 
msp.recv_date > DATEADD(MINUTE,-@CLIMAX_MINUTES_BEFORE,GETDATE()) and --respetando a partir de cuando
msp.task_no in (select task_no from @tasks_no) and -- que las tareas sean de climax
--ev.event_id in (select event_id from @image_events) -- que pertenezca a el o los eventos que traigan la url de imagen
--AND el hecho que en el rawmessage llegue @CLIMAX_END_URL_TAG implica que el evento es el que debe ser 1.2.7
msp.event_seqno > @last_msignal_processed_seqno
--(ev.aux2 not like 'V%'  -- y que el url no esté puesta en el aux2 de event_history
--OR 
--ev.aux2 is null)
and msp.raw_message like '%'+@CLIMAX_END_URL_TAG+'%' --
order by msp.event_seqno asc --para que entre en el cursor ordenado y procese de menor a mayor, para anotar el último



if(@@ROWCOUNT=0)
begin

print 'Nada para procesar'
end
else
begin
declare @filasProcesar as int
set @filasProcesar=(select count(1) from @events_seqs_no)
print 'Estoy ocupado, hay '+CONVERT(VARCHAR(MAX),@filasProcesar)+' filas a procesar.-..' 


declare seqno_index cursor local for select event_seqno from @events_seqs_no
open seqno_index
fetch next from seqno_index into @seqno
WHILE @@FETCH_STATUS = 0
BEGIN
			
			select @raw_message=raw_message,@lastSignal=recv_date from m_signal_processed 
			with(nolock) where event_seqno=@seqno

			

			set @ams_zone=SUBSTRING(@raw_message,CHARINDEX(@zone_start_tag,@raw_message)+LEN(@zone_start_tag),CHARINDEX(@zone_end_tag,@raw_message)-CHARINDEX(@zone_start_tag,@raw_message)-LEN(@zone_start_tag))-- 1.2.5
			set @link=SUBSTRING(@raw_message,CHARINDEX(@CLIMAX_START_URL_TAG,@raw_message)+LEN(@CLIMAX_START_URL_TAG),CHARINDEX(@CLIMAX_END_URL_TAG,@raw_message)-CHARINDEX(@CLIMAX_START_URL_TAG,@raw_message)-LEN(@CLIMAX_START_URL_TAG))
			--1.2.7 funcion de elegir si actualiza event history en aux2
			if(isnull(@CLIMAX_MAS_PREFIX,'Y')='Y')		
			begin
			set @linkcompleto='VF|MAS|'+@CLIMAX_HTTP_SERVER_URL+@link+@barra+@pipe --1.2.7
			set @linkcompleto=replace(@linkcompleto,'RECEIVER_IP',@ipReceptora) --1.2.7
			UPDATE event_history SET aux2=@linkcompleto WHERE seqno=@seqno and server_id=@server_id
			PRINT 'ACTUALIZANDO SEQNO '+CONVERT(VARCHAR(MAX),@seqno)+' server_id='+@server_id+' EN EVENT_HISTORY COMO @linkcompleto PROCESADO CON '+isnull(@linkcompleto,'null')
			end
			
			set @linkams=@CLIMAX_HTTP_SERVER_URL+@link+@barra --1.2.5
			/*26/04/2021 Si la variable @CLIMAX_HTTP_SERVER_URL no fue cargada en el task option, tendrá un valor por default,
			será @CLIMAX_HTTP_SERVER_URL='http://RECEIVER_IP/index.php?uri=', el replace, reemplazará RECEIVER_IP por la ip de la receptora pasada por parámetro,
			de esa manera, si entró por más de una receptora, el usuario será redireccionado con el link que corresponda, ya que las imágenes no redundan entre las receptoras.
			*/
			set @ipReceptora= substring(@link,CHARINDEX(@comienzoUrl,@link)+LEN(@comienzoUrl),CHARINDEX(@puertoImagenReceptora,@link)-CHARINDEX(@comienzoUrl,@link)-LEN(@comienzoUrl))
			--print @ipReceptora
			
			set @linkams=replace(@linkams,'RECEIVER_IP',@ipReceptora) --1.2.5
			

			-- 1/9/2021 v 1.2.5
			
			
			select @ams_cs_no=cs_no from system with(nolock)
			where system_no=
			(select system_no from event_history with(nolock) where seqno=@seqno and server_id=@server_id) -- debe ir server_id porque puede haber grupos, caso España
			-- 1.2.5
			set @ams_comment='url: '+@linkams+';'
			set @ams_comment=@ams_comment+char(13)+CHAR(10) -- new discover LB-> https://www.iteramos.com/pregunta/3556/como-insertar-un-salto-de-linea-en-una-cadena-de-varcharnvarchar-de-sql-server
			set @ams_comment=@startSeqnoTag+convert(varchar(max),@seqno)+@endSeqnoTag+@ams_comment

			-- Este salto de linea, exactamente tal cual está, es a proposito, para que aparezca en verde la linea event_history en MasterMind
	-- y el vinculo quede clickeable y asi abra la url de la foto
	-- descubrimiento by Frank


			exec dbo.ap_manual_signal 
			@ams_cs_no, 
			@ams_log_date,
			@ams_event_id , 
			@ams_zonestate_id, 
			@ams_zone, 
			@ams_user, 
			@ams_comment, 
			@ams_log_only, 
			@ams_recurse_flag,
			@ams_debug, 
			@ams_emp_no

			PRINT 'EVENTO MANUAL '+@ams_event_id+' INSERTADO EN ABONADO '+@ams_cs_no+' ZONA '+@ams_zone+' CON EL USUARIO '+@ams_user+' Y emp_no='+ CONVERT(VARCHAR(MAX),@ams_emp_no)

			set @last_msignal_processed_seqno=@seqno--1.2.7 guardo en memoria el ultimo procesado

			PRINT 'ULTIMO EVENT_SEQNO DE MSIGNAL_PROCESSED PROCESADO POR AP_CLIMAX -> '+CONVERT(VARCHAR(MAX),@last_msignal_processed_seqno)


			
		--	UPDATE event_history SET aux2=@linkcompleto WHERE seqno=@seqno and server_id=@server_id --1.2.3 --1.2.5 SE QUITA Y REEMPLAZA POR AP_MANUAL_SIGNAL
		--	UPDATE event_history SET aux2='VF' WHERE seqno=@seqno and server_id=@server_id --1.2.5 SE MARCA COMO PROCESADO
		 --   UPDATE event_history SET aux2=@linkcompleto WHERE seqno=@seqno and server_id=@server_id --1.2.6 se vuelve a activar a pedido de Frank

		     -- 1.2.6
		--	print @linkcompleto 1.2.5
			print @ams_comment
			
			-- vaciar variable 
			set @linkcompleto=null --19/08/2021 1.2.6
			set @ams_cs_no=null -- 1.2.5
			set @ams_comment=null -- 1.2.5
			
			
			
			fetch next from seqno_index into @seqno
END

CLOSE seqno_index
DEALLOCATE seqno_index



delete @events_seqs_no --19/08/2021 vaciar la tabla por performance.

print 'Saliendo del cursor y vaciando variable tabla @events_seqs_no'

set @registrosTabla=(select count(1) from @events_seqs_no)
print @registrosTabla+' registros por procesar'

end
--select * from @events_seqs_no
/*Ponemos la task de MAS en Normal*/

UPDATE m_task_current_status
				SET last_status_date = GETDATE(), taskstat_no = 1,
						last_error_msg = 'Normal',last_signal_date=@lastSignal,last_status=null
				WHERE task_no = @thisTask AND enable_flag = 'Y'
				print 'Actualizo Estado de la TASK'
				
WAITFOR DELAY @CLIMAX_DELAY_TIME


END-- FIN WHILE lb

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

