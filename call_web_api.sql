create or replace PACKAGE BODY             WS_POSHTIBANI_PKG AS
-----------------------------------------GET TICKET BY TICKET ID --------------------------------------------------
    FUNCTION GET_TICKET(IN_TICKET_ID IN NUMBER) RETURN NUMBER IS
        TICKET_RESPONSE             CLOB;
        HTTP_REQ                    UTL_HTTP.REQ;
        HTTP_RESP                   UTL_HTTP.RESP;
        V_RESPONSE                  CLOB;
        APP_USER_NAME               CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
        APP_TOKEN                   CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
        TICKET_REQUEST              CLOB; 
        V_JSON                      CLOB;
        V_TASKID                    NUMBER;
        V_SUPPORTGROUP              VARCHAR2(4000);
        V_SUPPORTTECHNICIAN         VARCHAR2(4000);
        V_DESCRIPTION               CLOB;
        V_TICKETSTATUS              NUMBER;
        V_TICKETCATEGORYID          VARCHAR2(4000);
        V_TICKETDETAILID            VARCHAR2(4000);
        V_OWNERNAME                 VARCHAR2(4000);
        V_LASTREPORT                VARCHAR2(4000);
        V_TICKET_STATUS             VARCHAR2(4000);
        V_TICKET_TYPE_ID            VARCHAR2(4000);
        V_PARENT_UNITNAME           VARCHAR2(4000);
        V_PARENT_UNITNAME2          VARCHAR2(4000);
        V_PARENT_UNITNAME3          VARCHAR2(4000);
        V_UNIT_NAME                 VARCHAR2(4000);
        V_RECORDER_NAME             VARCHAR2(4000);
        V_ATTACHMENT_COUNT          NUMBER;
        V_RECORDED_DATE_char        VARCHAR2(4000);
        V_RECORDED_DATE             DATE;
        L_GET_HISTORY               CLOB;
        WS_POSHTIBANI_ID            VARCHAR2(4000);
        L_MSG                       VARCHAR2(4000);  
        L_TYPE_NAME                 VARCHAR2(4000);
        EXIST_TICKET_ID             VARCHAR2(4000);
        L_LOG_DATE                  DATE;
        L_LOG_REPORT                VARCHAR2(4000);
        L_LOG_RECORDER              VARCHAR2(4000);
        L_TICKET_PERSON_IN_CHARGE   VARCHAR2(1000);
        L_TICKETING_MASTER_ID       NUMBER;
        L_CLOB                      CLOB;
        l_LAST_DETIAL               varchar2(4000);
        L_R                         VARCHAR2(4000);
     
    BEGIN
        
    IF LENGTH(IN_TICKET_ID) > 6 THEN
        RETURN -1;
        -- EM_RAISE('شماره تیکت وارد شده صحیح نیست !');
    END IF;


        TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
           <soap:Header/>
           <soap:Body>
              <tem:GetTicket>
                 <tem:appUerName>' || APP_USER_NAME || '</tem:appUerName>
                 <tem:appToken>' || APP_TOKEN || '</tem:appToken>
                 <tem:ticketID>' || IN_TICKET_ID || '</tem:ticketID>
              </tem:GetTicket>
           </soap:Body>
        </soap:Envelope>';
        HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
                
        
        UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'application/soap+xml;charset=UTF-8;');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', TO_CHAR(LENGTH(TICKET_REQUEST)));
        UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetTicket');
        UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
        HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
        UTL_HTTP.READ_TEXT(HTTP_RESP, TICKET_RESPONSE);
        UTL_HTTP.END_RESPONSE(HTTP_RESP);
        V_RESPONSE := TICKET_RESPONSE;
    
           IF HTTP_RESP.STATUS_CODE != 200 THEN 
                EM_RAISE('خطا در دریافت  تیکت لطفا دوباره تلاش کنید ');
        END IF;
        V_JSON := GET_XML_VALUE(V_RESPONSE,'<GetTicketResult>','</GetTicketResult>' ,1,1); 
        
                
        IF V_JSON = '{}' THEN 
            -- HTP.P(V_JSON);
            
            RETURN 0;
            -- EM_RAISE('تیکت یافت نشد !');
        END IF ;


        -- HTP.P(V_JSON);
        -- RETURN V_JSON;
    
        V_TASKID := JSON_VALUE(V_JSON, '$.taskID');
        V_SUPPORTGROUP := JSON_VALUE(V_JSON, '$.supportGroup');
        V_SUPPORTTECHNICIAN := JSON_VALUE(V_JSON, '$.supportTechnician');
        V_LASTREPORT := JSON_VALUE(V_JSON, '$.lastReport');
        V_DESCRIPTION := JSON_VALUE(V_JSON, '$.description');
        V_OWNERNAME := JSON_VALUE(V_JSON, '$.ownerName');
        V_TICKET_STATUS := JSON_VALUE(V_JSON, '$.ticketStatus');
        V_TICKETCATEGORYID := JSON_VALUE(V_JSON, '$.ticketCategoryID');
        V_TICKET_TYPE_ID := JSON_VALUE(V_JSON, '$.ticketTypeID');
        V_TICKETDETAILID := JSON_VALUE(V_JSON, '$.ticketDetailID');
        V_PARENT_UNITNAME := JSON_VALUE(V_JSON, '$.parent_unitname');
        V_PARENT_UNITNAME2 := JSON_VALUE(V_JSON, '$.parent_unitname2');
        V_PARENT_UNITNAME3 := JSON_VALUE(V_JSON, '$.parent_unitname3');
        V_UNIT_NAME := JSON_VALUE(V_JSON, '$.unitname');
        V_RECORDER_NAME := JSON_VALUE(V_JSON, '$.recorderName');
        V_ATTACHMENT_COUNT := JSON_VALUE(V_JSON, '$.attachmentCount');
        -- V_ATTACHMENT_COUNT := JSON_VALUE(V_JSON, '$.TICKET_DETAIL_ID');

        L_TYPE_NAME := 'GET_TICKET';


        SELECT COUNT(TICKET_ID) INTO EXIST_TICKET_ID   FROM WS_POSHTIBANI WHERE TICKET_ID = IN_TICKET_ID;

        V_LASTREPORT := REPLACE(V_LASTREPORT, '&lt;br/&gt;', CHR(10));
        V_DESCRIPTION := REPLACE(V_DESCRIPTION, '&lt;br/&gt;', CHR(10));

        V_RECORDED_DATE_char :=JSON_VALUE(V_JSON, '$.recordDate');
        V_RECORDED_DATE := TO_DATE(replace(substr(V_RECORDED_DATE_char,1,19),'T',''), 'YYYY-MM-DDHH24:MI:SS');
        V_RECORDED_DATE := TO_DATE(V_RECORDED_DATE, 'YYYY/MM/DD HH24:MI:SS','nls_calendar=gregorian');
        DELETE  WS_TICKET_HISTORY ;
         L_GET_HISTORY :=GET_TICKET_HISTORY(IN_TICKET_ID);
          
    
    -- INSERT_INTO_MASTER_AND_DETAIL(IN_TICKET_ID);
    

    IF EXIST_TICKET_ID = 0  THEN 
        INSERT INTO WS_POSHTIBANI (
         TICKET_ID, 
         TICKET_STATUS,
         TICKET_CATEGORY_ID, 
         TICKET_TYPE_ID, 
         TICKET_DETAIL_ID, 
         OWNER_NAME, 
         TICKET_DESCRIPTION,
         LAST_REPORT,
         SUPPORT_TECHNICIAN, 
         SUPPORT_GROUP, 
         TYPE_NAME, 
         JSON_DATA,
         FLAG_STATUS,
         PARENT_UNITNAME, 
         PARENT_UNITNAME_2, 
         PARENT_UNITNAME_3,
         RECORDER_NAME,
         ATTACHMENT_COUNT,
         UNIT_NAME,
         TASK_ID,
         RECORD_DATE)
        VALUES (
        IN_TICKET_ID, 
        V_TICKET_STATUS, 
        V_TICKETCATEGORYID,
        V_TICKET_TYPE_ID, 
        V_TICKETDETAILID,
        V_OWNERNAME, 
        V_DESCRIPTION,
        V_LASTREPORT, 
        V_SUPPORTTECHNICIAN, 
        V_SUPPORTGROUP, 
        L_TYPE_NAME,
        V_JSON,
        0,
        V_PARENT_UNITNAME,
        V_PARENT_UNITNAME2, 
        V_PARENT_UNITNAME3, 
        V_RECORDER_NAME,
        V_ATTACHMENT_COUNT,
        V_UNIT_NAME,
        V_TASKID,
        V_RECORDED_DATE);
                
  END IF;

    UPDATE WS_POSHTIBANI SET TASK_ID = V_TASKID WHERE TICKET_ID = IN_TICKET_ID;      
    UPDATE WS_POSHTIBANI SET TICKET_STATUS = V_TICKET_STATUS WHERE TICKET_ID = IN_TICKET_ID;      


        RETURN 1;
    
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            L_MSG := 'داده ای یافت نشد ';
            HTP.P(L_MSG);
    
    END;

    ----------------------------------------END  GET TICKET BY TICKET ID --------------------------------------------------

 FUNCTION  GET_TICKETS(IN_TICKET_STATUS IN NUMBER) RETURN CLOB IS
    TICKET_RESPONSE          CLOB;
    HTTP_REQ                UTL_HTTP.REQ;
    HTTP_RESP               UTL_HTTP.RESP;
    V_RESPONSE              CLOB;
    APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
    APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
    TICKET_REQUEST          CLOB; 
    V_JSON                  CLOB;
    V_TASKID                NUMBER;
    V_SUPPORTGROUP          VARCHAR2(4000);
    V_SUPPORTTECHNICIAN     VARCHAR2(4000);
    V_RECORDDATE            VARCHAR2(4000);
    V_DESCRIPTION           VARCHAR2(4000);
    V_TICKETSTATUS          NUMBER;
    V_TICKETCATEGORYID      VARCHAR2(4000);
    V_TICKETDETAILID        VARCHAR2(4000);
    V_OWNERNAME             VARCHAR2(4000);
    V_LASTREPORT            VARCHAR2(4000);
    V_TICKET_STATUS         VARCHAR2(4000);
    V_TICKET_TYPE_ID        VARCHAR2(4000);
    WS_POSHTIBANI_ID        VARCHAR2(4000);
    L_MSG                   VARCHAR2(4000);  
    L_TYPE_NAME             VARCHAR2(4000);
    V_FINAL                 CLOB;
    L_TEXT                  VARCHAR2(32766);
    L_CLOB                  CLOB;
    TEST_CLOB                CLOB;
    L_COUNT                   NUMBER;

    L_GET_HISTORY  CLOB;
    l_date TIMESTAMP         ;
    v_date  DATE;
    V_TICKET_PERSON_IN_CHARGE  VARCHAR2(100);
    V_TICKETING_MASTER_ID NUMBER;
    
BEGIN
    

TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
        <soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
           <soap:Header/>
           <soap:Body>
              <tem:GetTickets>
                <tem:appUerName>' || APP_USER_NAME || '</tem:appUerName>
                <tem:appToken>' || APP_TOKEN || '</tem:appToken>
                <tem:ticketStatus>'|| IN_TICKET_STATUS ||'</tem:ticketStatus>
            </tem:GetTickets>
           </soap:Body>
        </soap:Envelope>';

    HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'application/soap+xml;charset=UTF-8;');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', TO_CHAR(LENGTH(TICKET_REQUEST)));
    UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetTicket');
    UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
    HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
 
           IF HTTP_RESP.STATUS_CODE != 200 THEN 
                EM_RAISE('خطا در دریافت  تیکت ها لطفا دوباره تلاش کنید -- ERROR : 500 API ERROR --');
        END IF;
     BEGIN
         DBMS_LOB.createtemporary(L_CLOB, FALSE);
     LOOP
       UTL_HTTP.read_text(HTTP_RESP, L_TEXT, 32766);
       DBMS_LOB.writeappend (L_CLOB, LENGTH(L_TEXT), L_TEXT);
     END LOOP;
         EXCEPTION
              WHEN UTL_HTTP.end_of_body THEN
                 UTL_HTTP.end_response(http_resp);
     END;
     

    BEGIN

      l_clob := REPLACE(l_clob, '<![CDATA[[', ' [ ');
      l_clob := REPLACE(l_clob,'<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetTicketsResponse xmlns="http://tempuri.org/"><GetTicketsResult>','');
      l_clob := REPLACE(l_clob,'</GetTicketsResult></GetTicketsResponse></soap:Body></soap:Envelope>','');
    --   dbms_output.put_line(l_clob);
    --   insert into a_clob(col1) values(l_clob);

        --  return '';
   


  FOR POSHTIBANI_RECORD IN (
    SELECT *
    FROM JSON_TABLE(
      l_clob,
      '$[*]'
      COLUMNS (
        taskID NUMBER PATH '$.taskID',
        ticketID NUMBER PATH '$.ticketID',
        supportGroup VARCHAR2(100) PATH '$.supportGroup',
        supportTechnician VARCHAR2(100) PATH '$.supportTechnician',
        lastReport VARCHAR2(4000) PATH '$.lastReport',
        recordDate  VARCHAR2(4000) PATH '$.recordDate',
        Ldescription VARCHAR2(4000) PATH '$.description',
        ticketStatus VARCHAR2(100) PATH '$.ticketStatus',
        ticketCategoryID VARCHAR2(100) PATH '$.ticketCategoryID',
        ticketTypeID VARCHAR2(100) PATH '$.ticketTypeID',
        ticketDetailID VARCHAR2(100) PATH '$.ticketDetailID',
        ownerName VARCHAR2(100) PATH '$.ownerName',
        parent_unitname VARCHAR2(400) PATH '$.parent_unitname',
        parent_unitname2 VARCHAR2(400) PATH '$.parent_unitname2',
        parent_unitname3 VARCHAR2(400) PATH '$.parent_unitname3',
        unitname VARCHAR2(400) PATH '$.unitname',
        recorderName VARCHAR2(400) PATH '$.recorderName',
        attachmentCount NUMBER PATH '$.attachmentCount'
       
      )
    )
  ) LOOP
    -- INSERT INTO A_CLOB (COL1) VALUES(POSHTIBANI_RECORD.ticketID);
    POSHTIBANI_RECORD.recordDate := replace(POSHTIBANI_RECORD.recordDate,'T', ' ');
    POSHTIBANI_RECORD.recordDate := substr(POSHTIBANI_RECORD.recordDate,1,19);
    v_date := to_date(POSHTIBANI_RECORD.recordDate,'yyyy-mm-dd hh24:mi:ss','nls_calendar=gregorian');
    --raise_application_error(-20000,SUBSTR(POSHTIBANI_RECORD.recordDate,1,10));

 -- Insert the values into the table ws_poshtibani

    SELECT COUNT(TICKET_ID) INTO L_COUNT FROM WS_POSHTIBANI WHERE TICKET_ID = POSHTIBANI_RECORD.ticketID ;


  

    IF L_COUNT = 0 THEN
        INSERT INTO WS_POSHTIBANI
        (TICKET_ID,	
        TICKET_STATUS,
        TICKET_CATEGORY_ID,
        TICKET_TYPE_ID,
        TICKET_DETAIL_ID,
        OWNER_NAME,
        TICKET_DESCRIPTION,
        LAST_REPORT,
        SUPPORT_TECHNICIAN,
        SUPPORT_GROUP,
        TYPE_NAME,
        JSON_DATA,
        FLAG_STATUS,
        RECORD_DATE,
        TASK_ID,
        UNIT_NAME,
        PARENT_UNITNAME,
        PARENT_UNITNAME_2,
        PARENT_UNITNAME_3,
        ATTACHMENT_COUNT
        )
        VALUES (
            POSHTIBANI_RECORD.ticketID,
            POSHTIBANI_RECORD.ticketStatus,
            POSHTIBANI_RECORD.ticketCategoryID,
            POSHTIBANI_RECORD.ticketTypeID,
            POSHTIBANI_RECORD.ticketDetailID,
            POSHTIBANI_RECORD.ownerName,
            REPLACE(POSHTIBANI_RECORD.Ldescription, '&lt;br/&gt;', CHR(10)),
            REPLACE(POSHTIBANI_RECORD.lastReport, '&lt;br/&gt;', CHR(10)),
            POSHTIBANI_RECORD.supportTechnician,
            POSHTIBANI_RECORD.supportGroup,
            'GET_TICKETS',
            '',
            0,
            v_date,
            POSHTIBANI_RECORD.taskID,
            POSHTIBANI_RECORD.unitname,
             POSHTIBANI_RECORD.parent_unitname,
             POSHTIBANI_RECORD.parent_unitname2,
             POSHTIBANI_RECORD.parent_unitname3,
             POSHTIBANI_RECORD.attachmentCount
              
        );

    POSHTIBANI_PKG.INSERT_INTO_MASTER_AND_DETAIL(POSHTIBANI_RECORD.ticketID);
    L_GET_HISTORY :=GET_TICKET_HISTORY(POSHTIBANI_RECORD.ticketID);


    
        
      COMMIT;
     END IF; 


    commit;
  END LOOP;
                ----------------------update status to در دست اقدام

--   COMMIT;    
     RETURN '✔';

    END;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            -- L_MSG := 'عملیات ناموفق است ! لطفا دوباره تلاش کنید ';
            -- RE
            -- HTP.P(L_MSG);
            RETURN NULL;
END;
        


-----------------------------------GET TICKET ATTACHMENTS -------BY TICKET ID-------------------------------------------------
 FUNCTION GET_TICKET_ATTACHMENTS(IN_TICKET_ID IN NUMBER,IN_TICKETING_MASTER_ID IN NUMBER ) RETURN CLOB IS
        TICKET_RESPONSE          CLOB;
        HTTP_REQ                UTL_HTTP.REQ;
        HTTP_RESP               UTL_HTTP.RESP;
        V_RESPONSE              CLOB;
        APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
        APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
        TICKET_REQUEST          CLOB; 
        L_MSG                   VARCHAR2(4000);
        V_CONTENT_TYPE          CLOB;
        V_BINARY_CONTENT        CLOB;
        V_FILE_NAME             VARCHAR2(300);
        V_ATACHMENT_ID          NUMBER;
        V_UPLOADE_DATE          DATE;
        V_UPLOADE_DATE_char     VARCHAR2(100);
        L_TYPE_NAME             VARCHAR2(200);
        L_CLOB                   CLOB;
        L_COUNT                  NUMBER;
        L_COUNT_JSON             NUMBER;
        L_ARRAY_JSON             CLOB;
        EXIST_TICKET_ID          NUMBER;
        
    BEGIN
         
        TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
                <soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
                    <soap12:Body>
                        <GetTicketAttachments xmlns="http://tempuri.org/">
                            <appUerName>' || APP_USER_NAME || '</appUerName>
                            <appToken>'|| APP_TOKEN ||'</appToken>
                            <ticketID>'|| IN_TICKET_ID || '</ticketID>
                        </GetTicketAttachments>
                    </soap12:Body>
                </soap12:Envelope>';
    
        HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
        
        UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'application/soap+xml;charset=UTF-8;');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', TO_CHAR(LENGTH(TICKET_REQUEST)));
        UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetTicket');
        UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
        HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
                  

     BEGIN
         DBMS_LOB.createtemporary(L_CLOB, FALSE);
     LOOP
       UTL_HTTP.read_text(HTTP_RESP, TICKET_RESPONSE, 32766);
       DBMS_LOB.writeappend (L_CLOB, LENGTH(TICKET_RESPONSE), TICKET_RESPONSE);
     END LOOP;
         EXCEPTION
              WHEN UTL_HTTP.end_of_body THEN
                 UTL_HTTP.end_response(http_resp);
     END;

       V_RESPONSE := l_clob; 
    
        --221333 ✔
        --179284 ✔
        --236827
        --215330


           IF HTTP_RESP.STATUS_CODE != 200 THEN 
                EM_RAISE('خطا در دریافت ضمیمه تیکت لطفا دوباره تلاش کنید -- ERROR : 500 API ERROR --');
        END IF;

        V_RESPONSE := REPLACE(V_RESPONSE, '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetTicketAttachmentsResponse xmlns="http://tempuri.org/"><GetTicketAttachmentsResult>', ' ');
        V_RESPONSE := REPLACE(V_RESPONSE, '</GetTicketAttachmentsResult></GetTicketAttachmentsResponse></soap:Body></soap:Envelope>', ' ');

        -- V_UPLOADE_DATE_char :=JSON_VALUE(V_RESPONSE, '$.UploadeDate');
        -- V_UPLOADE_DATE := TO_DATE(replace(substr(V_UPLOADE_DATE_char,1,19),'T',''), 'YYYY-MM-DDHH24:MI:SS');
        L_TYPE_NAME :='GET_TICKET_ATTACHMENTS' ;


    FOR POSHTIBANI_RECORD_ATTACHMENT IN (
    SELECT *
    FROM JSON_TABLE(
      V_RESPONSE,
      '$[*]'
      COLUMNS (
        AttachmentID NUMBER PATH '$.AttachmentID',
        FileName VARCHAR2(4000) PATH '$.FileName',
        UploadeDate DATE PATH '$.UploadeDate',
        ContentType VARCHAR2(4000) PATH '$.ContentType',
        BinaryContent CLOB PATH '$.BinaryContent'
       )
    )
  ) LOOP


          --INSERT TICKET_ATTACHMENT(POSHTIBANI_RECORD.ticketID);

            
      INSERT INTO TICKET_ATTACHMENT(TICKETING_MASTER_ID,TICKET_ATTACHMENT,FILENAME,INTERNALOREXTERNAL,MIMETYPE,IS_REJECTED)
      VALUES 
 (IN_TICKETING_MASTER_ID,APEX_WEB_SERVICE.CLOBBASE642BLOB(POSHTIBANI_RECORD_ATTACHMENT.BinaryContent),POSHTIBANI_RECORD_ATTACHMENT.FileName,2,POSHTIBANI_RECORD_ATTACHMENT.ContentType,0);
    commit;
  END LOOP;

             RETURN('✔');

                EXCEPTION
          WHEN NO_DATA_FOUND THEN
            L_MSG := 'فایل مورد نظر یافت نشد !';
            HTP.P(L_MSG);
END;



FUNCTION GET_TICKET_ATTACHMENTS_TEST(IN_TICKET_ID IN NUMBER) RETURN CLOB IS
        TICKET_RESPONSE          CLOB;
        HTTP_REQ                UTL_HTTP.REQ;
        HTTP_RESP               UTL_HTTP.RESP;
        V_RESPONSE              CLOB;
        APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
        APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
        TICKET_REQUEST          CLOB; 
        L_MSG                   VARCHAR2(4000);
        V_CONTENT_TYPE          CLOB;
        V_BINARY_CONTENT        CLOB;
        V_FILE_NAME             VARCHAR2(300);
        V_ATACHMENT_ID          NUMBER;
        V_UPLOADE_DATE          DATE;
        V_UPLOADE_DATE_char     VARCHAR2(100);
        L_TYPE_NAME             VARCHAR2(200);
        L_CLOB                   CLOB;
        L_COUNT                  NUMBER;
        L_COUNT_JSON             NUMBER;
        L_ARRAY_JSON             CLOB;
        EXIST_TICKET_ID          NUMBER;
        
    BEGIN
         
        TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
                <soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
                    <soap12:Body>
                        <GetTicketAttachments xmlns="http://tempuri.org/">
                            <appUerName>' || APP_USER_NAME || '</appUerName>
                            <appToken>'|| APP_TOKEN ||'</appToken>
                            <ticketID>'|| IN_TICKET_ID || '</ticketID>
                        </GetTicketAttachments>
                    </soap12:Body>
                </soap12:Envelope>';
    
        HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
        
        UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'application/soap+xml;charset=UTF-8;');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', TO_CHAR(LENGTH(TICKET_REQUEST)));
        UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetTicket');
        UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
        HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
                  

     BEGIN
         DBMS_LOB.createtemporary(L_CLOB, FALSE);
     LOOP
       UTL_HTTP.read_text(HTTP_RESP, TICKET_RESPONSE, 32766);
       DBMS_LOB.writeappend (L_CLOB, LENGTH(TICKET_RESPONSE), TICKET_RESPONSE);
     END LOOP;
         EXCEPTION
              WHEN UTL_HTTP.end_of_body THEN
                 UTL_HTTP.end_response(http_resp);
     END;

       V_RESPONSE := l_clob; 
    
        --221333 ✔
        --179284 ✔
        --236827
        --215330


           IF HTTP_RESP.STATUS_CODE != 200 THEN 
                EM_RAISE('خطا در دریافت ضمیمه تیکت لطفا دوباره تلاش کنید -- ERROR : 500 API ERROR --');
        END IF;
       
        V_RESPONSE := REPLACE(V_RESPONSE, '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetTicketAttachmentsResponse xmlns="http://tempuri.org/"><GetTicketAttachmentsResult>', ' ');
        V_RESPONSE := REPLACE(V_RESPONSE, '</GetTicketAttachmentsResult></GetTicketAttachmentsResponse></soap:Body></soap:Envelope>', ' ');

        -- V_UPLOADE_DATE_char :=JSON_VALUE(V_RESPONSE, '$.UploadeDate');
        -- V_UPLOADE_DATE := TO_DATE(replace(substr(V_UPLOADE_DATE_char,1,19),'T',''), 'YYYY-MM-DDHH24:MI:SS');
        L_TYPE_NAME :='GET_TICKET_ATTACHMENTS' ;



    FOR POSHTIBANI_RECORD_ATTACHMENT IN (
    SELECT *
    FROM JSON_TABLE(
      V_RESPONSE,
      '$[*]'
      COLUMNS (
        AttachmentID NUMBER PATH '$.AttachmentID',
        FileName VARCHAR2(4000) PATH '$.FileName',
        UploadeDate DATE PATH '$.UploadeDate',
        ContentType VARCHAR2(4000) PATH '$.ContentType',
        BinaryContent CLOB PATH '$.BinaryContent'
       )
    )
  ) LOOP


--           INSERT TICKET_ATTACHMENT(POSHTIBANI_RECORD.ticketID);

            
--       INSERT INTO TICKET_ATTACHMENT(TICKETING_MASTER_ID,TICKET_ATTACHMENT,FILENAME,INTERNALOREXTERNAL,MIMETYPE)
--       VALUES 
--  (IN_TICKETING_MASTER_ID,APEX_WEB_SERVICE.CLOBBASE642BLOB(POSHTIBANI_RECORD_ATTACHMENT.BinaryContent),POSHTIBANI_RECORD_ATTACHMENT.FileName,2,POSHTIBANI_RECORD_ATTACHMENT.ContentType);

    DBMS_OUTPUT.PUT_LINE(POSHTIBANI_RECORD_ATTACHMENT.ContentType);


    commit;


    -- insert into WS_POSHTIBANI_ATTACHMENTS (BLOB_CONTENT,TICKET_ID,ATTACHMENT_ID,FILE_NAME) 
    -- VALUES(APEX_WEB_SERVICE.CLOBBASE642BLOB(POSHTIBANI_RECORD_ATTACHMENT.BinaryContent),IN_TICKET_ID,POSHTIBANI_RECORD_ATTACHMENT.AttachmentID,POSHTIBANI_RECORD_ATTACHMENT.FileName);
  END LOOP;

             RETURN('✔');

                EXCEPTION
          WHEN NO_DATA_FOUND THEN
            L_MSG := 'فایل مورد نظر یافت نشد !';
            HTP.P(L_MSG);
END;

--💡----For Updating ticket- task id is mandatory---------------------------------
-----------------------------------GET TICKET ATTACHMENTS -------BY TICKET ID-------------------------------------------------
FUNCTION UPDATE_TICKET(IN_TICKET_ID IN NUMBER,IN_TICKET_STATUS IN NUMBER,IN_TASK_ID NUMBER ,IN_LAST_REPORT IN VARCHAR2 ) RETURN NUMBER IS
        TICKET_RESPONSE          CLOB;
        HTTP_REQ                UTL_HTTP.REQ;
        HTTP_RESP               UTL_HTTP.RESP;
        V_RESPONSE              VARCHAR2(1000);
        APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
        APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
        TICKET_REQUEST          varchar2(4000); 
        V_JSON                  CLOB;
        WS_POSHTIBANI_ID        VARCHAR2(4000);
        L_MSG                   VARCHAR2(4000);  
        L_TYPE_NAME             VARCHAR2(4000);
        EXIST_TICKET_ID         VARCHAR2(4000);
        GET_TICKEY_BY_ID             CLOB;
        L_TASK_ID                    CLOB;
        L_LAST_REPORT                CLOB;
        L_TICKET_STATUS              CLOB;
        L_TICKET_STATUS_LAST         CLOB;
        V_GET_TICKET                NUMBER;
    BEGIN
    
    --2 IN PROGRESS
    --5 DONE
V_GET_TICKET := GET_TICKET(IN_TICKET_ID);
IF V_GET_TICKET = 0 THEN
     
    RETURN -1;
END IF;

TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
            <UpdateTicket xmlns="http://tempuri.org/">
                <appUerName>' || APP_USER_NAME || '</appUerName>
                <appToken>' || APP_TOKEN || '</appToken>
                <ticketID>' || IN_TICKET_ID || '</ticketID>
                 <taskID>' || IN_TASK_ID  ||'</taskID>
                <ticketStatus>' || IN_TICKET_STATUS || '</ticketStatus>
                <lastReport>' || IN_LAST_REPORT ||'</lastReport>
            </UpdateTicket>
        </soap:Body>
 </soap:Envelope>';
                -- <taskID>' || IN_TASK_ID  ||'</taskID>
    
        HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');

      

        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'text/xml;charset=UTF-8');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length',TO_CHAR(LENGTHB(TICKET_REQUEST)));
        UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/UpdateTicket');
        UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
        HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
        UTL_HTTP.READ_TEXT(HTTP_RESP, TICKET_RESPONSE);
        UTL_HTTP.END_RESPONSE(HTTP_RESP);
        V_RESPONSE := TICKET_RESPONSE;
       
   
       
        V_RESPONSE := REPLACE(V_RESPONSE, '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><UpdateTicketResponse xmlns="http://tempuri.org/"><UpdateTicketResult>', ' ');
        V_RESPONSE := REPLACE(V_RESPONSE, '</UpdateTicketResult></UpdateTicketResponse></soap:Body></soap:Envelope>', ' ');

   IF HTTP_RESP.STATUS_CODE != 200 THEN 
                
  
                RETURN 0;
                -- EM_RAISE('خطا در ارسال تیکت لطفا دوباره تلاش کنید -- ERROR : 500 API ERROR --');
        END IF;

        ---------------------update ws_poshtibani -----------------------------------------
        UPDATE WS_POSHTIBANI SET LAST_REPORT = IN_LAST_REPORT WHERE TICKET_ID = IN_TICKET_ID;
        ---------------------update ws_poshtibani -----------------------------------------


        dbms_output.put_line(V_RESPONSE);

        RETURN 1;


           EXCEPTION
          WHEN NO_DATA_FOUND THEN
            L_MSG := 'عملیات ناموفق است ! لطفا دوباره تلاش کنید ';
            HTP.P(L_MSG);

    END;

--💡----For Updating ticket- task id is mandatory---------------------------------


--------------------------------GET TICKET ATTACHMENTS------------------------------

----------------------------------GET TICKET HOSTORY -------BY TICKET ID-------------------------------------------------
FUNCTION GET_TICKET_HISTORY(IN_TICKET_ID IN NUMBER) RETURN CLOB IS
        TICKET_RESPONSE          CLOB;
        HTTP_REQ                UTL_HTTP.REQ;
        HTTP_RESP               UTL_HTTP.RESP;
        V_RESPONSE              clob;
        APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
        APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
        TICKET_REQUEST          varchar2(4000); 
        V_JSON                  CLOB;
        WS_POSHTIBANI_ID        VARCHAR2(4000);
        L_MSG                   VARCHAR2(4000);  
        V_DATE  date;
        L_COMMUTING_COUNT NUMBER;
        V_TIME VARCHAR2(100);

        V_LOG_RECORDER VARCHAR(3200);
    BEGIN


TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
            <GetTicketHistory xmlns="http://tempuri.org/">
                <appUerName>' || APP_USER_NAME || '</appUerName>
                <appToken>' || APP_TOKEN || '</appToken>
                <ticketID>' || IN_TICKET_ID || '</ticketID>
            </GetTicketHistory>
        </soap:Body>
 </soap:Envelope>';    
        HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'text/xml;charset=UTF-8');
        UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length',TO_CHAR(LENGTHB(TICKET_REQUEST)));
        UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetTicketHistory');
        UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
        HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
        UTL_HTTP.READ_TEXT(HTTP_RESP, TICKET_RESPONSE);
        UTL_HTTP.END_RESPONSE(HTTP_RESP);
        V_RESPONSE := TICKET_RESPONSE;

           IF HTTP_RESP.STATUS_CODE != 200 THEN 
                EM_RAISE('خطا در دریافت اریخچه تیکت لطفا دوباره تلاش کنید -- ERROR : 500 API ERROR --');
        END IF;
       
       
        V_RESPONSE := REPLACE(V_RESPONSE, '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetTicketHistoryResponse xmlns="http://tempuri.org/"><GetTicketHistoryResult>', ' ');
        V_RESPONSE := REPLACE(V_RESPONSE, '</GetTicketHistoryResult></GetTicketHistoryResponse></soap:Body></soap:Envelope>', ' ');


    DELETE WS_TICKET_HISTORY WHERE 	TICKET_ID=IN_TICKET_ID;
        -- DBMS_OUTPUT.PUT_LINE(V_JSON);

    
    FOR POSHTIBANI_HISTORY IN (
    SELECT *
    FROM JSON_TABLE(
      V_RESPONSE,
      '$[*]'
      COLUMNS (
        LogRecorder VARCHAR2(200) PATH '$.LogRecorder',
        logDate VARCHAR2 PATH '$.logDate',
        logReport VARCHAR2(4000) PATH '$.logReport'
       )
    )
  ) LOOP

            V_LOG_RECORDER :=  REPLACE(POSHTIBANI_HISTORY.logReport,'&gt;',' ');
            V_LOG_RECORDER :=  REPLACE(POSHTIBANI_HISTORY.logReport,'&lt;br;',' ');
            V_LOG_RECORDER :=  REPLACE(POSHTIBANI_HISTORY.logReport,'&lt;br/&gt;',' ');
            V_LOG_RECORDER :=  REPLACE(POSHTIBANI_HISTORY.logReport,'/lt;br&',' ');
            V_LOG_RECORDER :=  REPLACE(POSHTIBANI_HISTORY.logReport,'&gt;',' ');



        POSHTIBANI_HISTORY.logDate := TO_CHAR(TO_DATE(POSHTIBANI_HISTORY.logDate,'MM/DD/YYYY HH:MI:SS AM'),'YYYY/MM/DD HH:MI:SS AM');
        V_DATE := TO_DATE(POSHTIBANI_HISTORY.logDate, 'YYYY/MM/DD HH:MI:SS AM','nls_calendar=gregorian');

       V_TIME :=TO_CHAR(TO_DATE(V_DATE, 'YYYY/MM/DD HH24:MI:SS'), 'HH24:MI:SS');
      
        

        ---------------------INSERT WS_TICKET_HISTORY -----------------------------------------

   INSERT INTO WS_TICKET_HISTORY (TICKET_ID,LOG_RECORDER,LOG_DATE,LOG_REPORT,JSON_DATA) 
    VALUES (
    IN_TICKET_ID,
    POSHTIBANI_HISTORY.LogRecorder,
    V_DATE,
    REPLACE(V_LOG_RECORDER, '&lt;br/', CHR(10)),
    
    '{"LogRecorder":"' || POSHTIBANI_HISTORY.LogRecorder || '", "logDate":"' || POSHTIBANI_HISTORY.logDate || '", "logReport":"' || POSHTIBANI_HISTORY.logReport || '"}' );
  
    commit;



    -- DBMS_OUTPUT.PUT_LINE(V_DATE || '-----');
  END LOOP;
          ---------------------INSERT WS_TICKET_HISTORY -----------------------------------------

       
        RETURN('');

           EXCEPTION
          WHEN NO_DATA_FOUND THEN
            L_MSG := 'عملیا   ناموفق است ! لطفا دوباره تلاش کنید ';
            HTP.P(L_MSG);

    END;

--------------------------GET TICKET HOSTORY------------------------------------

-----------------------ADD_ATTACHMENT----------------------------------------
FUNCTION ADD_ATTACHMENT(IN_TICKET_ID IN NUMBER, IN_ATTACHMENT_FILE BLOB, IN_FILE_NAME IN VARCHAR2, IN_CONTENT_TYPE IN VARCHAR2) RETURN CLOB IS
    TICKET_RESPONSE          CLOB;
    HTTP_REQ                UTL_HTTP.REQ;
    HTTP_RESP               UTL_HTTP.RESP;
    V_RESPONSE              CLOB;
    APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
    APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
    TICKET_REQUEST          CLOB; 
    V_JSON                  CLOB;
    L_MSG                   VARCHAR2(100);  
    L_CLOB_ATTACHMENT       CLOB;
    L_CLOB                  CLOB;

    v_buffer          varchar2(32000); 
    l_xml xmltype;
    
BEGIN
    L_CLOB_ATTACHMENT := apex_web_service.blob2clobbase64(IN_ATTACHMENT_FILE);

    TICKET_REQUEST := '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:AddTicketAttachment>
         <!--Optional:-->
         <tem:appUerName>YOUR_USER_NAME</tem:appUerName>
         <!--Optional:-->
         <tem:appToken>FUCKING_TOKEN</tem:appToken>
         <tem:ticketID>'||IN_TICKET_ID||'</tem:ticketID>
         <!--Optional:-->
         <tem:filename>'||IN_FILE_NAME||'</tem:filename>
         <!--Optional:-->
         <tem:contentType>'|| IN_CONTENT_TYPE ||'</tem:contentType>
         <!--Optional:-->
         <tem:base64content>'|| L_CLOB_ATTACHMENT ||'</tem:base64content>
      </tem:AddTicketAttachment>
   </soapenv:Body>
</soapenv:Envelope>';
-- delete a_clob;
-- insert into a_clob(col1)values(TICKET_REQUEST);
-- commit;
    -- UTL_HTTP.SET_TRANSFER_TIMEOUT(180);

  l_xml := APEX_WEB_SERVICE.make_request(
    p_url      => 'http://192.168.102.60:8080/Services/Ticket.asmx',
    p_action   => '"http://tempuri.org/AddTicketAttachment"',
    p_envelope => TICKET_REQUEST
  );
--   -- Display the whole SOAP document returned.
    V_RESPONSE := REPLACE(l_xml.getClobVal(), '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><AddTicketAttachmentResponse xmlns="http://tempuri.org/"><AddTicketAttachmentResult>', ' ');
    L_CLOB := REPLACE(V_RESPONSE, '</AddTicketAttachmentResult></AddTicketAttachmentResponse></soap:Body></soap:Envelope>', ' ');


  DBMS_OUTPUT.put_line(L_CLOB);   
return '';

END;


-----ADD_ATTACHMENT----------------------------------------


----------------------------GET_LAST_TICKET_ID-----------------✔-------------------------------
FUNCTION GET_LAST_TASK_ID(IN_TICKET_ID IN NUMBER) RETURN CLOB IS
    TICKET_RESPONSE          CLOB;
    HTTP_REQ                UTL_HTTP.REQ;
    HTTP_RESP               UTL_HTTP.RESP;
    V_RESPONSE              VARCHAR(1000);
    APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
    APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
    TICKET_REQUEST          CLOB; 
    V_JSON                  CLOB;
    L_MSG                   VARCHAR2(100);       
    LAST_FINAL_TASK_ID            NUMBER;
BEGIN
    -- Construct the SOAP request
    TICKET_REQUEST := 
    '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <soap:Body>
            <GetLastTaskID xmlns="http://tempuri.org/">
                <appUerName>'|| APP_USER_NAME ||'</appUerName>
                <appToken>'|| APP_TOKEN ||'</appToken>
                <ticketID>'|| IN_TICKET_ID ||'</ticketID>
            </GetLastTaskID>
        </soap:Body>
    </soap:Envelope>';

    -- Send the SOAP request
    HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'text/xml; charset=utf-8;');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', LENGTH(TICKET_REQUEST));
    UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetLastTaskID');
    UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
    HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
    UTL_HTTP.READ_TEXT(HTTP_RESP, TICKET_RESPONSE);
    UTL_HTTP.END_RESPONSE(HTTP_RESP);
    V_RESPONSE := TICKET_RESPONSE;


      V_RESPONSE := REPLACE(V_RESPONSE,'<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetLastTaskIDResponse xmlns="http://tempuri.org/"><GetLastTaskIDResult>','');
      V_RESPONSE := REPLACE(V_RESPONSE,'</GetLastTaskIDResult></GetLastTaskIDResponse></soap:Body></soap:Envelope>',' ');
      V_RESPONSE := REPLACE(V_RESPONSE, '{', ' ');
      V_RESPONSE := REPLACE(V_RESPONSE, '}', ' ');
      V_RESPONSE := REPLACE(V_RESPONSE, '  "taskID": ', ' ');
      V_RESPONSE := REPLACE(V_RESPONSE,'.0','');

       LAST_FINAL_TASK_ID := TO_NUMBER(REGEXP_REPLACE(V_RESPONSE, '[^0-9]+', ''));
       ------------------------UPDATE LAST TASK_ID IN WS_POSHTIBANI-------------------------------
       UPDATE WS_POSHTIBANI SET LAST_TASK_ID = LAST_FINAL_TASK_ID WHERE TICKET_ID =IN_TICKET_ID ;
        ------------------------UPDATE LAST TASK_ID IN WS_POSHTIBANI-------------------------------
    DBMS_OUTPUT.PUT_LINE(LAST_FINAL_TASK_ID);

    RETURN '';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      L_MSG := 'داده ای یافت نشد ';
      HTP.P(L_MSG);
END;
----------------------------GET_LAST_TICKET_ID------------------------------------------------




-------------------------------------------GET_LAST_ID_2-----------------------------------------------

FUNCTION GET_LAST_TASK_ID_2(IN_TICKET_ID IN NUMBER) RETURN CLOB IS
    TICKET_RESPONSE          CLOB;
    HTTP_REQ                UTL_HTTP.REQ;
    HTTP_RESP               UTL_HTTP.RESP;
    V_RESPONSE              VARCHAR(1000);
    APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
    APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
    TICKET_REQUEST          CLOB; 
    V_JSON                  CLOB;
    L_MSG                   VARCHAR2(100);       
    LAST_FINAL_TASK_ID            NUMBER;
BEGIN
    -- Construct the SOAP request
    TICKET_REQUEST := 
    '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetLastTaskID2>
         <!--Optional:-->
         <tem:appUerName>'||APP_USER_NAME||'</tem:appUerName>
         <!--Optional:-->
         <tem:appToken>'||APP_TOKEN||'</tem:appToken>
         <tem:ticketID>'||IN_TICKET_ID||'</tem:ticketID>
      </tem:GetLastTaskID2>
   </soapenv:Body>
</soapenv:Envelope>';

    -- Send the SOAP request
    HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
    -- UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'text/xml; charset=utf-8;');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', LENGTH(TICKET_REQUEST));
    UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', 'http://tempuri.org/GetLastTaskID2');
    UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
    HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
    UTL_HTTP.READ_TEXT(HTTP_RESP, TICKET_RESPONSE);
    UTL_HTTP.END_RESPONSE(HTTP_RESP);
    V_RESPONSE := TICKET_RESPONSE;


      V_RESPONSE := REPLACE(V_RESPONSE,'<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetLastTaskID2Response xmlns="http://tempuri.org/"><GetLastTaskID2Result>',' ');
      V_RESPONSE := REPLACE(V_RESPONSE,'</GetLastTaskID2Result></GetLastTaskID2Response></soap:Body></soap:Envelope>',' ');
      V_RESPONSE := JSON_VALUE(V_RESPONSE, '$.taskID');
       ------------------------UPDATE LAST TASK_ID IN WS_POSHTIBANI-------------------------------
       UPDATE WS_POSHTIBANI SET LAST_TASK_ID = V_RESPONSE WHERE TICKET_ID =IN_TICKET_ID ;
        ------------------------UPDATE LAST TASK_ID IN WS_POSHTIBANI-------------------------------
    DBMS_OUTPUT.PUT_LINE(V_RESPONSE);

    RETURN '';

EXCEPTION
    WHEN NO_DATA_FOUND THEN
      L_MSG := 'داده ای یافت نشد ';
      HTP.P(L_MSG);
END;

-------------------------------------------GET_LAST_ID_2-----------------------------------------------


--------------GET REJECTED TICKETS --------------------------------------
FUNCTION  GET_REJECTED_TICKETS RETURN CLOB IS
    TICKET_RESPONSE          CLOB;
    HTTP_REQ                UTL_HTTP.REQ;
    HTTP_RESP               UTL_HTTP.RESP;
    V_RESPONSE              CLOB;
    APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
    APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
    TICKET_REQUEST          CLOB; 
    V_JSON                  CLOB;
    V_TASKID                NUMBER;
    V_SUPPORTGROUP          VARCHAR2(4000);
    V_SUPPORTTECHNICIAN     VARCHAR2(4000);
    V_RECORDDATE            VARCHAR2(4000);
    V_DESCRIPTION           VARCHAR2(4000);
    V_TICKETSTATUS          NUMBER;
    V_TICKETCATEGORYID      VARCHAR2(4000);
    V_TICKETDETAILID        VARCHAR2(4000);
    V_OWNERNAME             VARCHAR2(4000);
    V_LASTREPORT            VARCHAR2(4000);
    V_TICKET_STATUS         VARCHAR2(4000);
    V_TICKET_TYPE_ID        VARCHAR2(4000);
    WS_POSHTIBANI_ID        VARCHAR2(4000);
    L_MSG                   VARCHAR2(4000);  
    L_TYPE_NAME             VARCHAR2(4000);
    V_FINAL                 CLOB;
    L_TEXT                  VARCHAR2(32766);
    L_CLOB                  CLOB;
    TEST_CLOB                CLOB;
    L_COUNT                   NUMBER;
    L_GET_HISTORY               CLOB;
    l_date                      TIMESTAMP;
    v_date                      DATE;
    V_REJECTED_DATE         DATE;
    V_TICKET_PERSON_IN_CHARGE  VARCHAR2(100);
    V_TICKETING_MASTER_ID NUMBER;
    L_LOG_DATE              DATE;
    L_LOG_REPORT            VARCHAR2(4000);
    L_LOG_RECORDER          VARCHAR2(4000);
    L_TICKET_PERSON_IN_CHARGE VARCHAR2(1000);
    L_TICKETING_MASTER_ID     NUMBER;
    l_LAST_DETIAL            varchar2(4000);
    L_R                     VARCHAR2(4000);
    final_last_report       varchar(4000);
    IN_TICKETING_MASTER_ID  number;
    V_TICKET_ANSWER         VARCHAR2(1000);
    STATUS                  NUMBER;
    N_TICKETING_MOZO        TICKETING_DETAILE.TICKET_MOZO%TYPE;
BEGIN
TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <GetRejectedTickets xmlns="http://tempuri.org/">
      <appUerName>'||APP_USER_NAME||'</appUerName>
      <appToken>'||APP_TOKEN||'</appToken>
    </GetRejectedTickets>
  </soap:Body>
</soap:Envelope>';

    HTTP_REQ := UTL_HTTP.BEGIN_REQUEST('http://192.168.102.60:8080/Services/Ticket.asmx', 'POST', 'HTTP/1.1');
    UTL_HTTP.SET_BODY_CHARSET(HTTP_REQ,'UTF-8');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Type', 'text/xml;charset=UTF-8');
    UTL_HTTP.SET_HEADER(HTTP_REQ, 'Content-Length', TO_CHAR(LENGTH(TICKET_REQUEST)));
    UTL_HTTP.SET_HEADER(HTTP_REQ ,'SOAPAction', '"http://tempuri.org/GetRejectedTickets"');
    UTL_HTTP.WRITE_TEXT(HTTP_REQ, TICKET_REQUEST);
    HTTP_RESP := UTL_HTTP.GET_RESPONSE(HTTP_REQ);
 
     BEGIN
         DBMS_LOB.createtemporary(L_CLOB, FALSE);
     LOOP
       UTL_HTTP.read_text(HTTP_RESP, L_TEXT, 32766);
       DBMS_LOB.writeappend (L_CLOB, LENGTH(L_TEXT), L_TEXT);
     END LOOP;
         EXCEPTION
              WHEN UTL_HTTP.end_of_body THEN
                 UTL_HTTP.end_response(http_resp);
     END;

      
    --  htp.p(L_CLOB);

      l_clob := REPLACE(l_clob, '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><GetRejectedTicketsResponse xmlns="http://tempuri.org/"><GetRejectedTicketsResult>', ' ');
      l_clob := REPLACE(l_clob,'</GetRejectedTicketsResult></GetRejectedTicketsResponse></soap:Body></soap:Envelope>','');

    -- INSERT INTO P_CLOB(P_COL) VALUES(L_CLOB);
--  return '';
    BEGIN
        
   DELETE WS_REJECTED_POSHTIBANI;
  FOR POSHTIBANI_RECORD IN (
    SELECT *
    FROM JSON_TABLE(
      l_clob,
      '$[*]'
      COLUMNS (
        taskID NUMBER PATH '$.taskID',
        ticketID NUMBER PATH '$.ticketID',
        supportGroup VARCHAR2(100) PATH '$.supportGroup',
        supportTechnician VARCHAR2(100) PATH '$.supportTechnician',
        lastReport VARCHAR2(4000) PATH '$.lastReport',
        recordDate  VARCHAR2(4000) PATH '$.recordDate',
        Ldescription VARCHAR2(4000) PATH '$.description',
        ticketStatus VARCHAR2(100) PATH '$.ticketStatus',
        ticketCategoryID VARCHAR2(100) PATH '$.ticketCategoryID',
        ticketTypeID VARCHAR2(100) PATH '$.ticketTypeID',
        ticketDetailID VARCHAR2(100) PATH '$.ticketDetailID',
        ownerName VARCHAR2(100) PATH '$.ownerName',
        parent_unitname VARCHAR2(400) PATH '$.parent_unitname',
        parent_unitname2 VARCHAR2(400) PATH '$.parent_unitname2',
        parent_unitname3 VARCHAR2(400) PATH '$.parent_unitname3',
        unitname VARCHAR2(400) PATH '$.unitname',
        recorderName VARCHAR2(400) PATH '$.recorderName',
        attachmentCount NUMBER PATH '$.attachmentCount',
        attachments CLOB path '$.attachments',
        rejectDate  VARCHAR2(4000) PATH '$.rejectDate'
      )
    )
  ) LOOP
    POSHTIBANI_RECORD.recordDate := replace(POSHTIBANI_RECORD.recordDate,'T', ' ');
    POSHTIBANI_RECORD.recordDate := substr(POSHTIBANI_RECORD.recordDate,1,19);
    

    POSHTIBANI_RECORD.rejectDate := replace(POSHTIBANI_RECORD.rejectDate,'T', ' ');
    POSHTIBANI_RECORD.rejectDate := substr(POSHTIBANI_RECORD.rejectDate,1,19);
    
    
    V_REJECTED_DATE := to_date(POSHTIBANI_RECORD.rejectDate,'yyyy-mm-dd hh24:mi:ss','nls_calendar=gregorian');
    v_date := to_date(POSHTIBANI_RECORD.recordDate,'yyyy-mm-dd hh24:mi:ss','nls_calendar=gregorian');
    -- HTP.P(POSHTIBANI_RECORD.ticketID);
    
       SELECT 
        TICKET_PERSON_IN_CHARGE,
        TICKETING_MASTER_ID  ,TICKET_MOZO
        INTO   L_TICKET_PERSON_IN_CHARGE , L_TICKETING_MASTER_ID ,N_TICKETING_MOZO
        FROM TICKETING_DETAILE WHERE TICKETING_MASTER_ID = (SELECT TICKETING_MASTER_ID 
        FROM TICKETING_MASTER WHERE TICKET_NUMBER=POSHTIBANI_RECORD.ticketID) and rownum=1;



        INSERT INTO WS_REJECTED_POSHTIBANI
        (TICKET_ID,	
        TICKET_STATUS,
        TICKET_CATEGORY_ID,
        TICKET_TYPE_ID,
        TICKET_DETAIL_ID,
        OWNER_NAME,
        TICKET_DESCRIPTION,
        LAST_REPORT,
        SUPPORT_TECHNICIAN,
        SUPPORT_GROUP,
        TYPE_NAME,
        JSON_DATA,
        FLAG_STATUS,
        RECORD_DATE,
        TASK_ID,
        UNIT_NAME,
        PARENT_UNITNAME,
        PARENT_UNITNAME_2,
        PARENT_UNITNAME_3,
        ATTACHMENT_COUNT,
        REJECTED_DATE,
        TICKET_PERSON_IN_CHARGE	
        
        )
        VALUES (
            POSHTIBANI_RECORD.ticketID,
            POSHTIBANI_RECORD.ticketStatus,
            POSHTIBANI_RECORD.ticketCategoryID,
            POSHTIBANI_RECORD.ticketTypeID,
            POSHTIBANI_RECORD.ticketDetailID,
            POSHTIBANI_RECORD.ownerName,
            REPLACE(POSHTIBANI_RECORD.Ldescription, '&lt;br/&gt;', CHR(10)),
            REPLACE(POSHTIBANI_RECORD.lastReport, '&lt;br/&gt;', CHR(10)),
            POSHTIBANI_RECORD.supportTechnician,
            POSHTIBANI_RECORD.supportGroup,
            'GET_REJECTED_TICKET',
            '',
            0,
            v_date,
            POSHTIBANI_RECORD.taskID,
            POSHTIBANI_RECORD.unitname,
             POSHTIBANI_RECORD.parent_unitname,
             POSHTIBANI_RECORD.parent_unitname2,
             POSHTIBANI_RECORD.parent_unitname3,
             POSHTIBANI_RECORD.attachmentCount,
             V_REJECTED_DATE,
             L_TICKET_PERSON_IN_CHARGE
            
        );

        SELECT LAST_REPORT into final_last_report FROM WS_REJECTED_POSHTIBANI where  TICKET_ID=POSHTIBANI_RECORD.ticketID;

        SELECT TICKET_DETAIL into L_R FROM TICKETING_DETAILE
        WHERE TICKETING_MASTER_ID=(SELECT TICKETING_MASTER_ID FROM TICKETING_MASTER WHERE TICKET_NUMBER=POSHTIBANI_RECORD.ticketID)
        ORDER BY TICKETING_DETAILE_ID DESC
        FETCH FIRST ROW ONLY;

        SELECT TICKET_VAZIAT INTO STATUS 
        FROM TICKETING_DETAILE 
        WHERE TICKETING_MASTER_ID=(SELECT TICKETING_MASTER_ID FROM TICKETING_MASTER WHERE TICKET_NUMBER=POSHTIBANI_RECORD.ticketID) ORDER BY TICKETING_DETAILE_ID DESC FETCH FIRST ROW ONLY;
        

    -- IF () THEN

        IF (STATUS= 0 and trim(L_R) != trim(final_last_report) ) THEN
        
      INSERT INTO TICKETING_DETAILE (TICKET_PERSON_IN_CHARGE,TICKETING_MASTER_ID,TICKET_VAZIAT,TICKET_TARIKH_ERJA,TICKET_DETAIL,TICKET_MOZO)
      VALUES(L_TICKET_PERSON_IN_CHARGE,L_TICKETING_MASTER_ID,'2',SYSDATE,final_last_report,N_TICKETING_MOZO);
                 
                --  EM_RAISE('HERE');

    if POSHTIBANI_RECORD.attachments != '[]' then

    SELECT TICKETING_MASTER_ID INTO IN_TICKETING_MASTER_ID FROM TICKETING_MASTER WHERE TICKET_NUMBER=POSHTIBANI_RECORD.ticketID;


     FOR POSHTIBANI_RECORD_ATTACHMENT IN (
    SELECT *
    FROM JSON_TABLE(
      POSHTIBANI_RECORD.attachments,
      '$[*]'
      COLUMNS (
        AttachmentID NUMBER PATH '$.AttachmentID',
        FileName VARCHAR2(4000) PATH '$.FileName',
        UploadeDate DATE PATH '$.UploadeDate',
        ContentType VARCHAR2(4000) PATH '$.ContentType',
        BinaryContent CLOB PATH '$.BinaryContent'
       )
    )
  ) LOOP

      INSERT INTO TICKET_ATTACHMENT(TICKETING_MASTER_ID,TICKET_ATTACHMENT,FILENAME,INTERNALOREXTERNAL,MIMETYPE,IS_REJECTED)
      VALUES (IN_TICKETING_MASTER_ID,APEX_WEB_SERVICE.CLOBBASE642BLOB(POSHTIBANI_RECORD_ATTACHMENT.BinaryContent),POSHTIBANI_RECORD_ATTACHMENT.FileName,2,POSHTIBANI_RECORD_ATTACHMENT.ContentType,1);
  
  
  END LOOP;
    


    end if;


    END IF ;

      

  END LOOP;

     RETURN '✔';
    END;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          RETURN NULL;
            -- L_MSG := 'عملیات ناموفق است ! لطفا دوباره تلاش کنید ';
            -- HTP.P(L_MSG);
END;
--------------GET REJECTED TICKETS --------------------------------------

---------------------Return Ticket -----------------------------------------------

FUNCTION RETURN_TICKET(IN_TICKET_ID IN NUMBER,IN_RETURN_TEXT IN VARCHAR2,IN_TASK_ID IN NUMBER) RETURN CLOB IS
    TICKET_RESPONSE          CLOB;
    HTTP_REQ                UTL_HTTP.REQ;
    HTTP_RESP               UTL_HTTP.RESP;
    V_RESPONSE              VARCHAR(1000);
    APP_USER_NAME           CONSTANT VARCHAR2(100) := 'YOUR_USER_NAME'; 
    APP_TOKEN               CONSTANT VARCHAR2(1000) := 'FUCKING_TOKEN'; 
    TICKET_REQUEST          CLOB; 
    V_JSON                  CLOB;
    L_MSG                   VARCHAR2(100);       
    LAST_FINAL_TASK_ID            NUMBER;
    L_XML                       xmltype;
    V_FINAL_RESPONSE           VARCHAR2(1000);
    V_RECORDER_NAME            VARCHAR2(100);
BEGIN
    -- Construct the SOAP request
    TICKET_REQUEST := '<?xml version="1.0" encoding="utf-8"?>
<soap12:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap12="http://www.w3.org/2003/05/soap-envelope">
  <soap12:Body>
    <ReturnTicket xmlns="http://tempuri.org/">
      <appUerName>'||APP_USER_NAME||'</appUerName>
      <appToken>'||APP_TOKEN||'</appToken>
      <ticketID>'||IN_TICKET_ID||'</ticketID>
      <taskID>'||IN_TASK_ID||'</taskID>
      <returnReport>'||IN_RETURN_TEXT||'</returnReport>
    </ReturnTicket>
  </soap12:Body>
</soap12:Envelope>';
 

 l_xml := APEX_WEB_SERVICE.make_request(
    p_url      => 'http://192.168.102.60:8080/Services/Ticket.asmx',
    p_action   => '"http://tempuri.org/ReturnTicket"',
    p_envelope => TICKET_REQUEST
  );

    SELECT RECORDER_NAME INTO V_RECORDER_NAME FROM WS_POSHTIBANI WHERE TICKET_ID=IN_TICKET_ID;

      V_RESPONSE := REPLACE(l_xml.getClobVal(),'<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"><soap:Body><ReturnTicketResponse xmlns="http://tempuri.org/"><ReturnTicketResult>',' ');
      V_FINAL_RESPONSE := REPLACE(V_RESPONSE,'</ReturnTicketResult></ReturnTicketResponse></soap:Body></soap:Envelope>',' ');
   
       ------------------------INSERT INTO TICKETING_RETURN-------------------------------
            INSERT INTO TICKETING_RETURN (TICKET_ID,TICKET_RETURN_DESCRIPTION,TASK_ID,JSON_DATA)
                                    VALUES(IN_TICKET_ID,IN_RETURN_TEXT,IN_TASK_ID,V_FINAL_RESPONSE);
        ------------------------INSERT INTO TICKETING_RETURN-------------------------------
    -- DBMS_OUTPUT.PUT_LINE(V_FINAL_RESPONSE);
    RETURN '';
EXCEPTION
    WHEN NO_DATA_FOUND THEN
      L_MSG := 'داده ای یافت نشد ';
      RETURN(L_MSG);
END;

---------------------Return Ticket -----------------------------------------------

END WS_POSHTIBANI_PKG;
-----------------------------------------------POORIA_A---------------------------------------------;
/