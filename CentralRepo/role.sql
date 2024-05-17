--Tạo các role
CREATE ROLE r_Admin;
CREATE ROLE r_NhanVien;
CREATE ROLE r_KhachHang;
GO

--Cấp quyền quản lý toàn bộ database cho admin
GRANT CONTROL ON DATABASE::QUANLYCHUYENBAYmoi TO r_Admin;
GO

GRANT CONTROL ON SCHEMA::dbo TO r_Admin;
GO
												-- TẠO LOGIN CHO CÁC ROLE --
-- Tạo login cho admin
CREATE LOGIN admin_login WITH PASSWORD = 'yourAdminPassword';
GO

-- Tạo login cho nhân viên
CREATE LOGIN nhanvien_login WITH PASSWORD = 'yourNhanVienPassword';
GO

-- Tạo login cho khách hàng
CREATE LOGIN khachhang_login WITH PASSWORD = 'yourKhachHangPassword';
GO

												-- TẠO	USER CHO CÁC ROLE --
-- Tạo user cho admin
CREATE USER user_admin FOR LOGIN admin_login;
GO

-- Tạo user cho nhân viên
CREATE USER user_nhanvien FOR LOGIN nhanvien_login;
GO

-- Tạo user cho khách hàng
CREATE USER user_khachhang FOR LOGIN khachhang_login;
GO

-- Gán role cho user
ALTER ROLE r_Admin ADD MEMBER user_admin;
ALTER ROLE r_NhanVien ADD MEMBER user_nhanvien;
ALTER ROLE r_KhachHang ADD MEMBER user_khachhang;
GO

												-- CẤP QUYỀN THAO TÁC TRÊN BẢNG CHO CÁC ROLE --
--Cấp quyền quản lý các bảng cho nhân viên
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.CHUYENBAY TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.HOADON TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.VE TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.KHACHHANG TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.SANBAY TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.TUYENBAY TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.NHANVIEN TO r_NhanVien;
GRANT SELECT, INSERT, UPDATE, DELETE ON dbo.MAYBAY TO r_NhanVien;
GO

--Cấp quyền xem các bảng cho khách hàng
GRANT SELECT ON dbo.CHUYENBAY TO r_KhachHang;
GRANT SELECT ON dbo.VE TO r_KhachHang;
GRANT SELECT ON dbo.HOADON TO r_KhachHang;
GRANT SELECT ON dbo.KHACHHANG TO r_KhachHang;
GO

												--	CẤP QUYỀN THỰC THI FUNCTION CHO CÁC ROLE -- 
-- Cấp quyền thực thi function cho nhân viên
GRANT EXECUTE ON OBJECT::dbo.DEM_SLKHDK_THEOTHANG TO r_NhanVien;
GRANT EXECUTE ON OBJECT::dbo.DEM_SLCB_THEOTHANG TO r_NhanVien;
GRANT EXECUTE ON OBJECT::dbo.DOANHTHU TO r_NhanVien;
GRANT SELECT ON OBJECT::dbo.TIM_CHUYENBAY TO r_NhanVien;
GO

-- Cấp quyền thực thi function cho khách hàng
GRANT SELECT ON OBJECT::dbo.TIM_CHUYENBAY TO r_KhachHang;
GO

												-- CẤP QUYỀN THỰC THI PROCEDURE CHO CÁC ROLE --

-- Phân quyền thực thi PROC cho role nhân viên 
GRANT EXECUTE ON PRC_DanhSach_KhachHang TO r_NhanVien
GRANT EXECUTE ON PRC_DanhSach_NhanVien TO r_NhanVien;
GRANT EXECUTE ON PRC_DanhSach_HoaDon_NhanVien_DaTao TO r_NhanVien;
GRANT EXECUTE ON PRC_DanhSach_ChuyenBay_TheoNgay TO r_NhanVien;
GRANT EXECUTE ON PRC_DanhSach_ChuyenBay TO r_NhanVien;
GRANT EXECUTE ON PRC_DanhSach_HoaDon_KhachHang_DaThanhToan TO r_NhanVien;
GRANT EXECUTE ON PRC_DanhSach_Ve_Theo_MACB TO r_NhanVien;
GRANT EXECUTE ON PRC_ThemMoi_NhanVien TO r_NhanVien;
GRANT EXECUTE ON PRC_ThemMoi_ChuyenBay TO r_NhanVien;
GRANT EXECUTE ON PRC_ThemMoi_KhachHang TO r_NhanVien;
GRANT EXECUTE ON PRC_ThemMoi_Ve TO r_NhanVien;
GRANT EXECUTE ON PRC_ThemMoi_HoaDon TO r_NhanVien;
GRANT EXECUTE ON PRC_TongTienDaMua TO r_NhanVien;
GRANT EXECUTE ON PRC_CapNhat_GiaVe TO r_NhanVien;
GO

-- Phân quyền thực thi PROC cho role khách hàng 
GRANT EXECUTE ON PRC_DanhSach_ChuyenBay TO r_KhachHang;
GRANT EXECUTE ON PRC_DanhSach_HoaDon_KhachHang_DaThanhToan TO r_KhachHang;
GRANT EXECUTE ON PRC_DanhSach_Ve_Theo_MACB TO r_KhachHang;
GRANT EXECUTE ON PRC_DanhSach_ChuyenBay_TheoNgay TO r_KhachHang;
GRANT EXECUTE ON PRC_TongTienDaMua TO r_KhachHang;
GRANT EXECUTE ON PRC_View_KhachHang_ThongTin TO r_KhachHang;
GRANT EXECUTE ON dbo.PRC_View_KhachHang_ThongTin TO r_KhachHang;
GO 
