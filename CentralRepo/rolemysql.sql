-- PHÂN QUYỀN (ROLE & USER)
-- Tạo role
CREATE ROLE 'ADMIN_role';
CREATE ROLE 'EMPLOYEE_role';
CREATE ROLE 'CUSTOMER_role';

-- Tạo user
CREATE USER 'ADMIN_user'@'%' IDENTIFIED BY 'yourAdminPassword';
CREATE USER 'EMPLOYEE_user'@'%' IDENTIFIED BY 'yourEmployeePassword';
CREATE USER 'CUSTOMER_user'@'%' IDENTIFIED BY 'yourCustomerPassword';

-- Gán role cho user 
GRANT 'ADMIN_role' TO 'ADMIN_user'@'%';
SET DEFAULT ROLE 'ADMIN_role' to 'ADMIN_user'@'%';

GRANT 'EMPLOYEE_role' TO 'EMPLOYEE_user'@'%';
SET DEFAULT ROLE 'EMPLOYEE_role' to 'EMPLOYEE_user'@'%';

GRANT 'CUSTOMER_role' TO 'CUSTOMER_user'@'%';
SET DEFAULT ROLE 'CUSTOMER_role' to 'CUSTOMER_user'@'%';

-- Cấp quyền quản lý toàn bộ database cho admin
GRANT ALL PRIVILEGES ON FLIGHT_BOOKING.* TO 'ADMIN_role';

-- Cấp quyền thao tác trên bảng cho nhân viên
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.FLIGHT TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.INVOICE TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.TICKET TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.CUSTOMER TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.AIRPORT TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.ROUTE TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.EMPLOYEE TO 'EMPLOYEE_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON FLIGHT_BOOKING.AIRPLANE TO 'EMPLOYEE_role';

-- Cấp quyền xem các bảng cho khách hàng
GRANT SELECT ON FLIGHT_BOOKING.FLIGHT TO 'CUSTOMER_role';
GRANT SELECT ON FLIGHT_BOOKING.TICKET TO 'CUSTOMER_role';
GRANT SELECT ON FLIGHT_BOOKING.INVOICE TO 'CUSTOMER_role';
GRANT SELECT ON FLIGHT_BOOKING.CUSTOMER TO 'CUSTOMER_role';

-- Cấp quyền thực thi function cho nhân viên
GRANT EXECUTE ON FUNCTION FLIGHT_BOOKING.FUNC_CUSTOMER_SIGNUPS_BY_MONTH TO 'EMPLOYEE_role';
GRANT EXECUTE ON FUNCTION FLIGHT_BOOKING.FUNC_FLIGHTS_BY_MONTH TO 'EMPLOYEE_role';
GRANT EXECUTE ON FUNCTION FLIGHT_BOOKING.FUNC_REVENUE TO 'EMPLOYEE_role';

-- Cấp quyền thực thi procedure cho nhân viên
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_CUSTOMER_LIST TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_EMPLOYEE_LIST TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_INVOICE_PER_EMPLOYEE TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_INVOICE_PURCHASED TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHTS_BY_DATE TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHT_LIST TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING. PRC_TICKET_LISTBY_FLIGHT TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_EMPLOYEE_ADD TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHT_ADD TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_CUSTOMER_ADD TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_TICKET_ADD TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_INVOICE_ADD TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_CUSTOMER_TOTAL_PURCHASE TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_PRICE_UPDATE TO 'EMPLOYEE_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHT_SEARCH TO 'EMPLOYEE_role';

-- Cấp quyền thực thi procedure cho khách hàng
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHT_LIST TO 'CUSTOMER_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_INVOICE_PURCHASED TO 'CUSTOMER_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_TICKET_LISTBY_FLIGHT TO 'CUSTOMER_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHTS_BY_DATE TO 'CUSTOMER_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_CUSTOMER_TOTAL_PURCHASE TO 'CUSTOMER_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_CUSTOMER_LIST TO 'CUSTOMER_role';
GRANT EXECUTE ON PROCEDURE FLIGHT_BOOKING.PRC_FLIGHT_SEARCH TO 'CUSTOMER_role';

FLUSH PRIVILEGES;
