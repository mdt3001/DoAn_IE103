--Tạo các role
CREATE ROLE Admin;
CREATE ROLE NhanVien;
CREATE ROLE KhachHang;
GO

--Cấp quyền quản lý toàn bộ database cho admin
GRANT CONTROL ON DATABASE::QUANLYCHUYENBAYmoi TO Admin;
GO

GRANT CONTROL ON SCHEMA::dbo TO Admin;
GO

--Cấp quyền quản lý cho nhân viên
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.CHUYENBAY TO NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.HOADON TO NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.VE TO NhanVien;
GO

--Cấp quyền cho khách hàng
GRANT SELECT ON dbo.CHUYENBAY TO KhachHang;
GRANT SELECT ON dbo.VE TO KhachHang;
GO

-- Tạo login cho admin
CREATE LOGIN admin_login WITH PASSWORD = 'yourAdminPassword';
GO

-- Tạo login cho nhân viên
CREATE LOGIN nhanvien_login WITH PASSWORD = 'yourNhanVienPassword';
GO

-- Tạo login cho khách hàng
CREATE LOGIN khachhang_login WITH PASSWORD = 'yourKhachHangPassword';
GO

-- Tạo user cho admin
CREATE USER user_admin FOR LOGIN admin_login;
GO

-- Tạo user cho nhân viên
CREATE USER user_nhanvien FOR LOGIN nhanvien_login;
GO

-- Tạo user cho khách hàng
CREATE USER user_khachhang FOR LOGIN khachhang_login;
GO
