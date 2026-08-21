create or replace package ut_pkg_orders as

    --%suite(Orders Package Tests)
    --%suitepath(orders)

    --%test(Calculate Total - Valid Discount)
    procedure calculate_total_valid;

    --%test(Calculate Total - Null Code / No Discount)
    procedure calculate_total_null_code;

    --%test(Calculate Total - Invalid Code / No Discount)
    procedure calculate_total_invalid_code;

    --%test(Calculate Total - Negative Amount raises valid error)
    --%throws(-20001)
    procedure calculate_total_invalid_amount;

end ut_pkg_orders;
/

create or replace package body ut_pkg_orders as

    procedure calculate_total_valid is
        l_actual   number;
        l_expected number := 90; -- 100 - 10%
    begin
        -- Act
        l_actual := pkg_orders.calculate_total(100, 'WELCOME10');
        
        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_valid;

    procedure calculate_total_null_code is
        l_actual   number;
        l_expected number := 100; -- No discount
    begin
        -- Act
        l_actual := pkg_orders.calculate_total(100, null);
        
        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_null_code;

    procedure calculate_total_invalid_code is
        l_actual   number;
        l_expected number := 100; -- No discount
    begin
        -- Act
        l_actual := pkg_orders.calculate_total(100, 'INVALID');

        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_invalid_code;

    procedure calculate_total_invalid_amount is
        l_result number;
    begin
        -- Act (Should raise exception defined in spec --%throws)
        l_result := pkg_orders.calculate_total(-50, 'WELCOME10');
    end calculate_total_invalid_amount;

end ut_pkg_orders;
/
