create or replace package ut_pkg_orders as

    --%suite(Orders Package Tests)
    --%suitepath(orders)

    --%test(Calculate Total - Valid Discount)
    procedure calculate_total_valid;

    --%test(Calculate Total - Second Valid Discount Code)
    procedure calculate_total_second_valid_code;

    --%test(Calculate Total - Null Code / No Discount)
    procedure calculate_total_null_code;

    --%test(Calculate Total - Lowercase Code / No Discount)
    procedure calculate_total_lowercase_code;

    --%test(Calculate Total - Whitespace Code / No Discount)
    procedure calculate_total_whitespace_code;

    --%test(Calculate Total - Near-Miss Code / No Discount)
    procedure calculate_total_near_miss_code;

    --%test(Calculate Total - Invalid Discount Code)
    procedure calculate_total_invalid_code;

    --%test(Calculate Total - Negative Amount raises valid error)
    --%throws(-20001)
    procedure calculate_total_invalid_amount;

    --%test(Calculate Total - Zero Amount)
    procedure calculate_total_zero_amount;

end ut_pkg_orders;
/

create or replace package body ut_pkg_orders as

    procedure calculate_total_valid is
        l_actual   number;
        l_expected number := 90; -- 100 - 10%
    begin
        -- Relies on the default 'WELCOME10' -> 0.10 seed row from src/schema_discounts.sql
        -- Act
        l_actual := pkg_orders.calculate_total(100, 'WELCOME10');
        
        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_valid;

    procedure calculate_total_second_valid_code is
        l_actual   number;
        l_expected number := 160; -- 200 - 20%
    begin
        -- Arrange: seed a second distinct discount code within the test transaction
        -- (utPLSQL automatically rolls back DML after test execution)
        merge into discounts d
        using (select 'SAVE20' as discount_code, 0.20 as discount_factor from dual) s
           on (d.discount_code = s.discount_code)
         when matched then
             update set d.discount_factor = s.discount_factor
         when not matched then
             insert (discount_code, discount_factor)
             values (s.discount_code, s.discount_factor);

        -- Act
        l_actual := pkg_orders.calculate_total(200, 'SAVE20');

        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_second_valid_code;

    procedure calculate_total_null_code is
        l_actual   number;
        l_expected number := 100; -- No discount
    begin
        -- Act
        l_actual := pkg_orders.calculate_total(100, null);
        
        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_null_code;

    procedure calculate_total_lowercase_code is
        l_actual   number;
        l_expected number := 100;
    begin
        -- Codes match the literal WELCOME10; do not normalize their case.
        l_actual := pkg_orders.calculate_total(100, 'welcome10');

        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_lowercase_code;

    procedure calculate_total_whitespace_code is
        l_actual   number;
        l_expected number := 100;
    begin
        -- Codes match exact literals; leading/trailing whitespace is not trimmed.
        l_actual := pkg_orders.calculate_total(100, ' WELCOME10 ');

        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_whitespace_code;

    procedure calculate_total_near_miss_code is
        l_actual   number;
        l_expected number := 100;
    begin
        -- A valid prefix must not grant a discount to a different code.
        l_actual := pkg_orders.calculate_total(100, 'WELCOME100');

        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_near_miss_code;

    procedure calculate_total_invalid_code is
        l_actual   number;
        l_expected number := 100; -- No discount for invalid code
    begin
        -- Act
        l_actual := pkg_orders.calculate_total(100, 'INVALID');

        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_invalid_code;

    procedure calculate_total_invalid_amount is
    begin
        -- Act (Should raise exception defined in spec --%throws)
        ut.expect(pkg_orders.calculate_total(-50, 'WELCOME10')).to_be_null();
    end calculate_total_invalid_amount;

    procedure calculate_total_zero_amount is
        l_actual   number;
        l_expected number := 0;
    begin
        -- Act
        l_actual := pkg_orders.calculate_total(0, 'WELCOME10');

        -- Assert
        ut.expect(l_actual).to_equal(l_expected);
    end calculate_total_zero_amount;

end ut_pkg_orders;
/
