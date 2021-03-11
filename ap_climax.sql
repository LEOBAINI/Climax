USE [MonitorDB]
GO
/****** Object:  StoredProcedure [dbo].[ap_climax]    Script Date: 03/11/2021 17:05:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[ap_climax] @task_no integer
AS
BEGIN
BEGIN TRY

	
	
	/*
	Solución.
	
	Algoritmo buscar en m_signal_processed las tramas que entraron por las task xxxx y revisar si su correspondiente
	aux2 con el evento definido, en event_history está vacío, en el caso de estarlo, completar según algoritmo de parseo.
	
	*/
	
/*INICIO -> INICIALIZACIÓN DE SETTINGS*/

/*serán los seqno del event_history que cumplan la condición*/

set nocount on;
declare @events_seqs_no as table (event_seqno integer,aux2 varchar(max))
declare @image_events as table (event_id varchar(10))
declare @tasks_no as table (task_no integer)
declare @minutosHaciaAtrasInicial as integer
--ejemplo packet sender S011[#8888|NBA*'<LINK>http://10.24.34.23:8899/capture_event/media/35000009/2021-02-11/2021-02-11_124646_39_06/35000009_012a3930_2021-02-11_134646_006.jpg<LINK/>']    <6>
declare @seqno as integer
declare @raw_message as varchar(max)
declare @link as varchar(max)
declare @prefijomas as varchar(max)
declare @linkcompleto as varchar(max)
declare @pipe as varchar(1)
declare @barra as varchar(1)
declare @caracteriniciourl as varchar(max)
declare @caracterfinurl as varchar(max)
declare @urlPhp as varchar (max)
declare @delayTime as varchar(12)
declare @maxRowsProcessing as integer
declare @lastSignal as dateTime /*Probar para poner el la ultima señal recibida de Climax*/
set @lastSignal=GETDATE()

/*El tiempo que tarda en hacer cada chequeo contra Master
Respetar formato hh:mm:ss.mmm*/
set @delayTime='00:00:03:000'
/*minutos hacia atrás que mirará eventos a tratar a partir de inicio de programa*/
set @minutosHaciaAtrasInicial=180 -- tres horas por default al arranque
/*inicializar con las tasks por las que entra Climax*/
insert into @tasks_no values (44), (1111), (284)
/*inicializar los eventos que traen imágen*/
insert into @image_events values ('PEPE'),('CIE609')
/*Etiquetas de inicio y fin del URL del directorio http*/
set @caracteriniciourl='<LINK>'
set @caracterfinurl='<LINK/>'
/*El caracter PIPE*/
set @pipe='|'
set @barra='//'
set @prefijomas='VF|MAS|'
set @urlPhp='http://localhost:81/LB/IMAGEN5.PHP?uri='
set @maxRowsProcessing=200
/*FIN -> INICIALIZACIÓN DE SETTINGS*/




while (1=1)

begin
/*Cargando los seqno que hay que tratar*/
insert into @events_seqs_no
select top (@maxRowsProcessing) msp.event_seqno,ev.aux2  from m_signal_processed msp with(nolock)
inner join event_history ev on ev.seqno=msp.event_seqno
where 
msp.recv_date > DATEADD(MINUTE,-@minutosHaciaAtrasInicial,GETDATE())and --respetando a partir de cuando
msp.task_no in (select task_no from @tasks_no) and -- que las tareas sean de climax
ev.event_id in (select event_id from @image_events) -- que pertenezca a el o los eventos que traigan la url de imagen
AND
(ev.aux2 not like 'VF|MAS|http%' -- y que el url no esté puesta en el aux2 de event_history
OR 
ev.aux2 is null)
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
select @raw_message=raw_message,@lastSignal=recv_date from m_signal_processed with(nolock) where event_seqno=@seqno

			set @link=SUBSTRING(@raw_message,CHARINDEX(@caracteriniciourl,@raw_message)+LEN(@caracteriniciourl),CHARINDEX(@caracterfinurl,@raw_message)-CHARINDEX(@caracteriniciourl,@raw_message)-LEN(@caracteriniciourl))
			set @linkcompleto=@prefijomas+@urlPhp+@link+@barra+@pipe
			
			UPDATE event_history SET aux2=@linkcompleto WHERE seqno=@seqno
			PRINT @seqno
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
				WHERE task_no = 1 AND enable_flag = 'Y'
				print 'Actualizo Estado de la TASK'
WAITFOR DELAY @delayTime


END-- FIN WHILE

END TRY


BEGIN CATCH
			print @@error
END CATCH

END

