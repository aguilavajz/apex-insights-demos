-- Run Tests Script
set serveroutput on size unlimited format wrapped
set linesize 120

prompt Running orders_suite...
begin
    -- Run the specific path defined in the suite annotation
    ut.run('orders');
end;
/
