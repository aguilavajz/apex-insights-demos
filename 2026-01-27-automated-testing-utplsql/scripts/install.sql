-- Installation Script
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode failure

prompt Installing Schema (discounts table)...
@../src/schema_discounts.sql

prompt Installing Business Logic (pkg_orders)...
@../src/pkg_orders.sql

prompt Installing Unit Tests (ut_pkg_orders)...
@../tests/ut_pkg_orders.sql

prompt Installation verification...
select object_name, status 
  from user_objects 
 where object_name in ('PKG_ORDERS', 'UT_PKG_ORDERS')
 order by object_name;

prompt Done.
