-- Tạo các role tương ứng
CREATE ROLE MANAGER_US; -- Giám đốc 
CREATE ROLE NV_QLCB; -- Nhân viên quản lý chuyến bay
CREATE ROLE NV_QLDT; -- Nhân viên quản lý doanh thu
CREATE ROLE NV_DV; -- Nhân viên đặt vé
CREATE ROLE KHACHHANG; -- Khách hàng

-- Gán quyền cho role MANAGER_US (Giám đốc)
GRANT SELECT, INSERT, UPDATE, DELETE ON MAYBAY TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON SANBAY TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON TUYENBAY TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON CHUYENBAY TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON VAITRO TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON NHANVIEN TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON KHACHHANG TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON HOADON TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON HANGVE TO MANAGER_US;
GRANT SELECT, INSERT, UPDATE, DELETE ON VE TO MANAGER_US;

-- Gán quyền cho role NV_QLCB (Nhân viên quản lý chuyến bay)
GRANT SELECT, INSERT, UPDATE, DELETE ON MAYBAY TO NV_QLCB;
GRANT SELECT, INSERT, UPDATE, DELETE ON SANBAY TO NV_QLCB;
GRANT SELECT, INSERT, UPDATE, DELETE ON TUYENBAY TO NV_QLCB;
GRANT SELECT, INSERT, UPDATE, DELETE ON CHUYENBAY TO NV_QLCB;
GRANT SELECT ON VE TO NV_QLCT;

-- Gán quyền cho role NV_QLDT (Nhân viên quản lý doanh thu)
GRANT SELECT ON HOADON TO NV_QLDT;
GRANT SELECT ON VE TO NV_QLDT;

-- Gán quyền cho role NV_DV (Nhân viên đặt vé)
GRANT SELECT, INSERT, UPDATE ON KHACHHANG TO NV_DV;
GRANT SELECT, INSERT, UPDATE ON HOADON TO NV_DV;
GRANT SELECT, INSERT, UPDATE ON VE TO NV_DV;

-- Gán quyền cho role KHACHHANG (Khách hàng)
GRANT SELECT, INSERT, UPDATE ON KHACHHANG TO KHACHHANG;
GRANT SELECT, INSERT, UPDATE ON HOADON TO KHACHHANG;
GRANT SELECT, INSERT, UPDATE ON VE TO KHACHHANG;
