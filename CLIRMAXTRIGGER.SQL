USE [MonitorDB]
GO

/****** Object:  Trigger [dbo].[CLIMAX]    Script Date: 03/03/2021 14:32:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- EJEMPLO DE URL GENERADA http://localhost:81/LB/IMAGEN5.PHP?uri=http://10.24.34.23:8899/capture_event/media/35000009/2021-02-11/2021-02-11_124646_39_06/




ALTER TRIGGER [dbo].[CLIMAX]
   ON  [dbo].[m_signal_processed]
   AFTER INSERT
AS 
BEGIN-- comienzo trigger
BEGIN TRY --Comienzo logica
--ejemplo packet sender S011[#8888|NBA*'<LINK>http://10.24.34.23:8899/capture_event/media/35000009/2021-02-11/2021-02-11_124646_39_06/35000009_012a3930_2021-02-11_134646_006.jpg<LINK/>']    <6>
declare @seqno as integer
declare @raw_message as varchar(max)
declare @link as varchar(max)
declare @prefijomas as varchar(max)
declare @linkcompleto as varchar(max)
declare @task_no as integer
declare @pipe as varchar(1)
declare @caracteriniciourl as varchar(max)
declare @caracterfinurl as varchar(max)
declare @urlPhp as varchar (max)
set @caracteriniciourl='<LINK>'
set @caracterfinurl='<LINK/>'
set @pipe='|'
set @prefijomas='VF|MAS|'
set @urlPhp='http://localhost:81/LB/IMAGEN5.PHP?uri='
select 
@seqno=event_seqno,
@task_no=task_no,
@raw_message=raw_message
from inserted

if @task_no IN (44, 1111, 284)--climax
	begin -- inicio if task_no=44
		if CHARINDEX(@caracteriniciourl,@raw_message)>1 -- si contiene caracterinicio link recièn procesamos, es para que procese lo menos posible
		begin-- inicio si contiene http
			set @link=SUBSTRING(@raw_message,CHARINDEX(@caracteriniciourl,@raw_message)+LEN(@caracteriniciourl),CHARINDEX(@caracterfinurl,@raw_message)-CHARINDEX(@caracteriniciourl,@raw_message)-LEN(@caracteriniciourl))
			set @linkcompleto=@prefijomas+@urlPhp+@link+@pipe
			UPDATE event_history SET aux2=@linkcompleto WHERE seqno=@seqno
		end -- fin si contiene http

	end-- fin if task_no=44
	--exec darerror
	--SELECT 1/0-- PROVOCAMOS ERROR EN CUALQUIER CASO
END TRY
BEGIN CATCH
			IF(XACT_STATE())=1
			COMMIT TRANSACTION
		
	 /*  RAISERROR ('Error en Trigger CLIMAX de m_signal_processed', -- Message text.  
               0, -- Severity.  
               0 -- State.  
               );  
               */
END CATCH
END-- fin comienzo trigger



GO


