CREATE OR REPLACE package xxpm_Auto_Billing_pkg
is

procedure createBilling(P_TRANS_ID 		IN NUMBER,
						P_FUN_ID			IN NUMBER,
                        P_LOGIN_USER        IN VARCHAR2,
						P_ERROR_CODE 	OUT VARCHAR2,
						P_ERR_MSG		OUT VARCHAR2
						);

end xxpm_Auto_Billing_pkg;
/


CREATE OR REPLACE PACKAGE body xxpm_Auto_Billing_pkg
is

procedure createBilling(P_TRANS_ID 		IN NUMBER,
						P_FUN_ID			IN NUMBER,
                        P_LOGIN_USER    IN VARCHAR2,    
						P_ERROR_CODE 	OUT VARCHAR2,
						P_ERR_MSG		OUT VARCHAR2
						)
AS 
l_bill_fun_id number;
l_bill_id number;
l_bill_number varchar2(60);
l_funCode varchar2(30);
l_booking_id number;
l_org_id number;
l_proj_id number;
l_cancel_type VARCHAR2(30);
l_charge_type VARCHAR2(30);
V_p_func_id number;
l_description   VARCHAR2(60); 
V_p_err_code           VARCHAR2(30);
V_p_err_msg            VARCHAR2(30);
l_ERROR_CODE       VARCHAR2(30):= '500';
l_ERR_MSG          VARCHAR2(30):= 'failed'; 
l_exit_cust_id       Number;
l_exit_cust_ship_to  Number;
l_exit_book_cust_id  number;
l_TO_CUSTOMER          number;
l_TO_CUSTOMER_BILL_TO number;
l_TO_CUSTOMER_CONTACTS  number;

cursor booking_milestone_info(l_bill_id NUMBER)
IS 
SELECT
    booking_ms_dtl_id
FROM
    xxpm_booking_milestones
WHERE
    billing_id = l_bill_id;



BEGIN
-- get function code

SELECT FUNC_SHORT_CODE into l_funCode
FROM xxfnd_functions 
where FUNC_ID=P_FUN_ID;
dbms_output.put_line('function code l_funCode-->'|| l_funCode);
--checking screen type
IF l_funCode IN ('CN','UNTRNS','SP','RS') THEN
select 
can.booking_id , 
bh.org_id   , 
pro.PROJ_ID,
can.CANCEL_TYPE
into l_booking_id,l_org_id,l_proj_id, l_cancel_type
from xxpm_cancellation can, xxpm_booking_header bh, xxstg_projects pro
where 
can.booking_id=bh.BOOKING_HDR_ID
and pro.ORG_ID=bh.ORG_ID
and can.CANCEL_ID=P_TRANS_ID
and can.FUNC_ID=P_FUN_ID ;
--and can.CANCEL_TYPE= l_funCode;

if l_funCode ='CN' THEN
l_description:='Cancellation Auto Billing';
l_charge_type:='CN_CHG';
end if;
if l_funCode ='UNTRNS' THEN
l_description:='Unit Transfer Auto Billing';
l_charge_type:='UN_CHG';
end if;
if l_funCode ='SP' THEN
l_description:='Swapping Auto Billing';
l_charge_type:='SW_CHG';
end if;
if l_funCode ='RS' THEN
l_description:='Resale Auto Billing';
l_charge_type:='RS_CHG';
end if;

dbms_output.put_line('l_booking_id-->'|| l_booking_id);
dbms_output.put_line('l_org_id-->'|| l_org_id);
dbms_output.put_line('l_proj_id-->'|| l_proj_id);
dbms_output.put_line('l_cancel_type-->'|| l_cancel_type);
dbms_output.put_line('l_charge_type-->'|| l_charge_type);
END IF;
--Creating one billing
begin
if (l_org_id is not null and l_proj_id is not null and l_cancel_type is not null) then

l_bill_id:=XXPM_BILLING_S.nextval;
l_bill_fun_id:=20;

INSERT INTO xxpm_billing
(
BILLING_ID               
,BILLING_NUMBER           
,BILLING_DATE             
,USAGE                    
,ORG_ID                   
,STATUS                   
,DESCRIPTION              
,FUNC_ID                  
,FLOW_STATUS              
,FLOW_LEVEL               
,FLOW_WITH                
,USER_GRP_ID              
,CREATED_BY               
,CREATION_DATE            
,LAST_UPDATED_BY          
,LAST_UPDATE_DATE         
,LAST_UPDATE_LOGIN        
,PROJECT_ID )
VALUES
(
l_bill_id,
'BL-'||l_bill_id,
sysdate,
'S',
l_org_id,
'APR',
l_description,
l_bill_fun_id,
null,
null,
null,
null,
P_LOGIN_USER,
systimestamp,
P_LOGIN_USER,
systimestamp,
P_LOGIN_USER,
l_proj_id
);
commit;
-- updatin new billing id in booking milestone

if l_funCode IN ('CN','UNTRNS','SP','RS') THEN
dbms_output.put_line('Completed-> 0 l_bill_id-->'|| l_bill_id);
dbms_output.put_line('Completed-> 0 P_FUN_ID-->'|| P_FUN_ID);
dbms_output.put_line('Completed-> 0 P_TRANS_ID-->'|| P_TRANS_ID);
dbms_output.put_line('Completed-> 0 l_booking_id-->'|| l_booking_id);
dbms_output.put_line('Completed-> 0 l_charge_type-->'|| l_charge_type);
--updating billing id in booking milestone
update xxpm_booking_milestones
set BILLING_ID=l_bill_id
where 
CUST_TYPE='EXIT_CUST'
and SOURCE_FUNC_ID=P_FUN_ID
and SOURCE_FUNC_REF_ID=P_TRANS_ID
and BOOKING_HDR_ID=l_booking_id
and CHARGE_TYPE=l_charge_type
and BILLING_ID is null;
commit;
end if;
dbms_output.put_line('if End-> 0 ');
end if;
end;
-- calling billing to invoice 
begin
--begin
--xxpm_bill_invoice_pkg.load_invoice (l_bill_id, P_ERROR_CODE,P_ERR_MSG);
--EXCEPTION
--WHEN no_data_found THEN
--    P_ERROR_CODE := SQLCODE ;
--    P_ERR_MSG :=P_ERR_MSG||'Error billing to invoice'|| '-' || SQLERRM;
--    DBMS_OUTPUT.PUT_LINE('exception no data found   ');
--end;

FOR ms_id in booking_milestone_info(l_bill_id)
loop
begin
dbms_output.put_line('Billing-->ms_id.booking_ms_dtl_id->'||ms_id.booking_ms_dtl_id);
xxpm_bill_invoice_pkg.ms_based_invoice (ms_id.booking_ms_dtl_id, P_ERROR_CODE,P_ERR_MSG);
dbms_output.put_line('Billing to invoice--P_ERROR_CODE->'||P_ERROR_CODE);
dbms_output.put_line('PKG--P_ERR_MSG->'||P_ERR_MSG);
EXCEPTION
  WHEN no_data_found THEN
    P_ERROR_CODE := SQLCODE ;
    P_ERR_MSG :=P_ERR_MSG||'Error billing to invoice'|| '-' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('exception no data found   ');
end;
end loop;
end;

--get exiting Customer information
begin
select 
BOOKING_CUST_ID ,
CUST_ID        ,    
SHIP_TO_SITE_ID
into 
l_exit_book_cust_id,
l_exit_cust_id       ,
l_exit_cust_ship_to  
from xxpm_booking_customer
where 
rownum=1
and PRIMARY_YN='Y'
and BOOKING_HDR_ID=l_booking_id;

exception
when no_data_found then
    P_ERROR_CODE := SQLCODE ;
    P_ERR_MSG :=P_ERR_MSG||'Customer is not primary'|| '-' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Customer is not primary   ');
end;
dbms_output.put_line('Billing to invoice--l_exit_book_cust_id->'||l_exit_book_cust_id);
dbms_output.put_line('Billing to invoice--l_exit_cust_id->'||l_exit_cust_id);
dbms_output.put_line('Billing to invoice--l_exit_cust_ship_to->'||l_exit_cust_ship_to);
----removing exiting customer primary
begin
update xxpm_booking_customer
set PRIMARY_YN=null
where 
BOOKING_CUST_ID=l_exit_book_cust_id
and CUST_ID=l_exit_cust_id
and SHIP_TO_SITE_ID=l_exit_cust_ship_to
and BOOKING_HDR_ID=l_booking_id;
exception
when no_data_found then
    P_ERROR_CODE := SQLCODE ;
    P_ERR_MSG :=P_ERR_MSG||'Error in primary Package   '|| '-' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Error in primary Package   ');
end;
---- inserting new customer
---- get new customer from unit transfer table
begin
select 
TO_CUSTOMER, 
TO_CUSTOMER_BILL_TO, 
TO_CUSTOMER_CONTACTS
into
l_TO_CUSTOMER,
l_TO_CUSTOMER_BILL_TO, 
l_TO_CUSTOMER_CONTACTS
from UNIT_TRANSFER_DETAILS
where 
FROM_CUSTOMER=l_exit_cust_id 
and FROM_CUSTOMER_BILL_TO=l_exit_cust_ship_to
and CANCEL_ID=P_TRANS_ID 
and BOOKING_HDR_ID=l_booking_id
and UNIT_TRANSFER_STATUS ='N';
exception
when no_data_found then
    P_ERROR_CODE := SQLCODE ;
    P_ERR_MSG :=P_ERR_MSG||'Error in Getting new customer   '|| '-' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Error in Getting new customer   ');
end;
dbms_output.put_line('Billing to invoice--l_TO_CUSTOMER->'||l_TO_CUSTOMER);
dbms_output.put_line('Billing to invoice--l_TO_CUSTOMER_BILL_TO->'||l_TO_CUSTOMER_BILL_TO);
dbms_output.put_line('Billing to invoice--l_TO_CUSTOMER_CONTACTS->'||l_TO_CUSTOMER_CONTACTS);
dbms_output.put_line('inserting one record in booking customer');
--inserting one record in booking customer
begin
if(l_TO_CUSTOMER is not null and l_TO_CUSTOMER_BILL_TO is not null) then
dbms_output.put_line('l_TO_CUSTOMER is not null and l_TO_CUSTOMER_BILL_TO is not null'||l_TO_CUSTOMER||l_TO_CUSTOMER_BILL_TO);
INSERT INTO xxpm_booking_customer
(
 BOOKING_CUST_ID          
,BOOKING_HDR_ID           
,CUST_ID                  
,SHIP_TO_SITE_ID          
,BILL_TO_SITE_ID          
,CUST_CONTACT_ID          
,PRIMARY_YN               
,DESCRIPTION              
,ATTRIBUTE_CATEGORY       
,ATTRIBUTE1               
,ATTRIBUTE2               
,ATTRIBUTE3               
,ATTRIBUTE4               
,ATTRIBUTE5               
,ATTRIBUTE6               
,ATTRIBUTE7               
,ATTRIBUTE8               
,ATTRIBUTE9               
,ATTRIBUTE10              
,ATTRIBUTE11              
,ATTRIBUTE12              
,ATTRIBUTE13              
,ATTRIBUTE14              
,ATTRIBUTE15              
,ATTRIBUTE16              
,ATTRIBUTE17              
,ATTRIBUTE18              
,ATTRIBUTE19              
,ATTRIBUTE20              
,CREATED_BY               
,CREATION_DATE            
,LAST_UPDATED_BY          
,LAST_UPDATE_DATE         
,LAST_UPDATE_LOGIN
)
VALUES
(
XXPM_BOOKING_CUSTOMER_S.nextval   
,l_booking_id   
,l_TO_CUSTOMER             
,l_TO_CUSTOMER_BILL_TO  
,l_TO_CUSTOMER_BILL_TO  
,l_TO_CUSTOMER_CONTACTS
,'Y'       
,'On '|| sysdate||'- New Customer added from Unit Transfer process'
,null
,null       
,null       
,null
,null
,null
,null
,null
,null
,null
,null 
,null
,null
,null
,null
,null
,null
,null
,null
,null
,null
,P_LOGIN_USER       
,systimestamp    
,P_LOGIN_USER  
,systimestamp 
,P_LOGIN_USER
);
--updating unit transfer details flag and approving unit transfer status
dbms_output.put_line('updating unit transfer details flag and approving unit transfer status');
begin
UPDATE UNIT_TRANSFER_DETAILS
SET UNIT_TRANSFER_STATUS='Y'
WHERE 
    TO_CUSTOMER=l_TO_CUSTOMER
AND TO_CUSTOMER_BILL_TO=l_TO_CUSTOMER_BILL_TO
AND BOOKING_HDR_ID=l_booking_id
AND CANCEL_ID=P_TRANS_ID
AND UNIT_TRANSFER_STATUS ='N';
commit;
end;
--UPDATING CANCELATION AS 'APR'
dbms_output.put_line('UPDATING CANCELATION AS APR');
begin
UPDATE XXPM_CANCELLATION
SET STATUS='APR'
WHERE CANCEL_ID=P_TRANS_ID
AND BOOKING_ID=l_booking_id;
commit;
end;
end if;
exception
when no_data_found then
    P_ERROR_CODE := SQLCODE ;
    P_ERR_MSG :=P_ERR_MSG||' Error in insert line   '|| '-' || SQLERRM;
      DBMS_OUTPUT.PUT_LINE('Error in insert line   ');
end;
--commit;
l_ERROR_CODE := '200';
l_ERR_MSG    := 'Success'; 
P_ERROR_CODE:=l_ERROR_CODE;
P_ERR_MSG:=l_ERR_MSG;
EXCEPTION
  WHEN no_data_found THEN
    P_ERROR_CODE := SQLCODE || '-' || SQLERRM;
    P_ERR_MSG :='Error';
      DBMS_OUTPUT.PUT_LINE('exception no data found   ');
END createBilling;
end xxpm_Auto_Billing_pkg;
/
