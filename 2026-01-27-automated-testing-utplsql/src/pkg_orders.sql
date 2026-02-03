create or replace package pkg_orders as
    -- Constant for standard discount
    c_standard_discount constant number := 0.10; -- 10%

    /**
     * Calculates the total amount after applying a discount code.
     * 
     * @param p_amount        The original order amount. Must be non-negative.
     * @param p_discount_code The discount code (e.g., 'WELCOME10').
     * @return                The final amount.
     * @throws                -20001 if amount is negative.
     */
    function calculate_total(
        p_amount        in number,
        p_discount_code in varchar2 default null
    ) return number;

end pkg_orders;
/

create or replace package body pkg_orders as

    function calculate_total(
        p_amount        in number,
        p_discount_code in varchar2 default null
    ) return number is
        l_total number := p_amount;
    begin
        if p_amount < 0 then
            raise_application_error(-20001, 'Order amount cannot be negative');
        end if;

        if p_discount_code = 'WELCOME10' then
            l_total := l_total - (l_total * c_standard_discount);
        end if;

        return l_total;
    end calculate_total;

end pkg_orders;
/
