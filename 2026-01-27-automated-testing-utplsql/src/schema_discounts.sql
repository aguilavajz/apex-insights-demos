-- Table to store discount codes and their factors
create table discounts (
    discount_code   varchar2(50) primary key,
    discount_factor number       not null check (discount_factor >= 0 and discount_factor <= 1)
);

-- Seed with initial discount code
insert into discounts (discount_code, discount_factor)
values ('WELCOME10', 0.10);

commit;
