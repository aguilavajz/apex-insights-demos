-- Table to store discount codes and their factors.
-- Drop existing table first so re-running scripts/install.sql is idempotent.
begin
    execute immediate 'drop table discounts purge';
exception
    when others then
        if sqlcode != -942 then
            raise;
        end if;
end;
/

-- discount_factor must be strictly between 0 and 1 (0 < discount_factor < 1),
-- rejecting zero-effect (0%) and full-waiver (100%) discount rows.
create table discounts (
    discount_code   varchar2(50) primary key,
    discount_factor number       not null check (discount_factor > 0 and discount_factor < 1)
);

-- Seed with initial discount code
insert into discounts (discount_code, discount_factor)
values ('WELCOME10', 0.10);

commit;
