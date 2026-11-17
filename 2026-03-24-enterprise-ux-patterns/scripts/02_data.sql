-- DML for demo_invoices
-- Populating with initial states to test dynamic visibility and UI logic
INSERT INTO demo_invoices (client_name, amount, status, due_date) VALUES ('Acme Corp', 5000, 'DRAFT', SYSDATE+10);
INSERT INTO demo_invoices (client_name, amount, status, due_date) VALUES ('Global Tech', 12000, 'PENDING', SYSDATE+5);
INSERT INTO demo_invoices (client_name, amount, status, due_date) VALUES ('Innova S.A.', 8500, 'APPROVED', SYSDATE-2);
COMMIT;
