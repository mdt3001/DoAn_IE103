--CÂU 1
--Hiển thị danh sách khách hàng
GO
CREATE PROC PRC_DanhSach_KhachHang
AS
BEGIN
    SELECT * FROM KHACHHANG
END

EXEC PRC_DanhSach_KhachHang 

--CÂU 2: Hiển thị danh sách nhân viên
GO
CREATE PROC PRC_DanhSach_NhanVien
AS
BEGIN
    SELECT * FROM NHANVIEN
END

EXEC PRC_DanhSach_NhanVien

--CÂU 4: Hiển thị danh sách các hoá đơn do 1 nhân viên đã tạo
GO
CREATE PROC PRC_DanhSach_HoaDon_NhanVien_DaTao
(
    @MANV CHAR(8)
)
AS
BEGIN 
    SELECT * FROM HOADON WHERE MANV = @MANV
END

--CÂU 6: Hiển thị danh sách các chuyến bay theo ngày
GO 
CREATE PROC PRC_DanhSach_ChuyenBay_TheoNgay
(
    @NGAYKHOIHANH SMALLDATETIME
)
AS
BEGIN
    SELECT * FROM CHUYENBAY WHERE NGAYKHOIHANH = @NGAYKHOIHANH
END

SELECT * FROM CHUYENBAY
EXEC PRC_DanhSach_ChuyenBay_TheoNgay '2025-03-17'

--CÂU 8: Thêm mới một nhân viên, trước khi thêm kiểm tra xem MANV đã tồn tại hay không, và MAVT đã tồn tại trong bảng VAITRO chưa
GO
CREATE PROC PRC_ThemMoi_NhanVien
(
    @MANV CHAR(8),
    @TENNV NVARCHAR(50),
    @DIACHI NCHAR(50),
    @SDT VARCHAR(10),
    @NGAYSINH SMALLDATETIME,
    @NGAYVAOLAM SMALLDATETIME,
    @GIOITINH NCHAR(3),
    @EMAIL VARCHAR(50),
    @PASSWORD VARCHAR(50),
    @NGAYTAOTK DATETIME,
    @MAVT CHAR(8)
)
AS 
BEGIN
    IF EXISTS (SELECT * FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        PRINT N'MANV đã tồn tại'
    END
    ELSE IF NOT EXISTS (SELECT * FROM VAITRO WHERE MAVT = @MAVT)
    BEGIN
        PRINT N'MAVT không tồn tại'
    END
    ELSE
    BEGIN
        INSERT INTO NHANVIEN VALUES(@MANV, @TENNV, @DIACHI, @SDT, @NGAYSINH, @NGAYVAOLAM, @GIOITINH, @EMAIL, @PASSWORD, @NGAYTAOTK, @MAVT)
    END
END

SELECT*FROM NHANVIEN

EXEC PRC_ThemMoi_NhanVien 'NV999999', N'Nguyễn Văn A', N'123 ABC', '0123456789', '1999-03-17', '2024-03-17', N'Nam', 'wff@ffb', 'wgjsj','2024-03-17', 'kV'

-- Câu 12: Thêm mới một chuyến bay 
GO 
CREATE PROC PRC_ThemMoi_ChuyenBay
(
    @MACB CHAR(8),
    @MATB CHAR(8),
    @MAMB CHAR (8),
    @NGAYKHOIHANH DATE,
    @GIOKHOIHANH TIME,
    @THOIGIANDUKIEN TIME
)
AS
BEGIN
    IF EXISTS (SELECT * FROM CHUYENBAY WHERE MACB = @MACB)
    BEGIN
        PRINT N'MACB đã tồn tại'
    END
    ELSE IF NOT EXISTS (SELECT * FROM TUYENBAY WHERE MATB = @MATB)
    BEGIN
        PRINT N'MATB không tồn tại'
    END
    ELSE IF NOT EXISTS (SELECT * FROM MAYBAY WHERE MAMB = @MAMB)
    BEGIN
        PRINT N'MAMB không tồn tại'
    END
    ELSE
    BEGIN
        INSERT INTO CHUYENBAY(MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) VALUES(@MACB, @MATB, @MAMB, @NGAYKHOIHANH, @GIOKHOIHANH, @THOIGIANDUKIEN)
    END
END

EXEC PRC_ThemMoi_ChuyenBay 'CB999999', 'ABK-BBW', '0GXHYZ', '2025-03-17', '12:00:00', '02:00:00'

--CÂU 14: Tính tổng tiền đã thanh toán thành công của một khách hàng 
GO
CREATE PROC PRC_TongTienDaMua 
(
    @MAKH CHAR(8),
    @TONGTIENDATHANHTOAN MONEY OUTPUT
)
AS
BEGIN
    SELECT @TONGTIENDATHANHTOAN = SUM(THANHTIEN) FROM HOADON WHERE MAKH = @MAKH AND TINHTRANG = 1
END

GO 
DECLARE @tongtien MONEY
EXEC PRC_TongTienDaMua @MAKH='KH002015', @TONGTIENDATHANHTOAN=@tongtien OUTPUT
PRINT @tongtien

--3) Hiển thị danh sách các chuyến bay
CREATE PROCEDURE PRC_DanhSach_ChuyenBay AS
BEGIN
	SELECT * FROM CHUYENBAY
END;

GO
EXEC PRC_DanhSach_ChuyenBay
GO


--5) Hiển thị danh sách các hoá đơn đã thanh toán của 1 khách hàng
CREATE PROC PRC_DanhSach_HoaDon_KhachHang_DaThanhToan (@makh CHAR(8)) AS
BEGIN
	SELECT * FROM HOADON
	WHERE TINHTRANG = '1' AND MAKH = @makh;
END

GO
EXEC PRC_DanhSach_HoaDon_KhachHang_DaThanhToan 'KH000001';
GO

--7) Hiển thị danh sách các vé theo mã chuyến bay
CREATE PROC PRC_DanhSach_Ve_Theo_MACB (@macb CHAR(8)) AS
BEGIN
	SELECT * FROM VE
	WHERE MACB = @macb;
END

GO
EXEC PRC_DanhSach_Ve_Theo_MACB 'VB 795'
GO

--9) Thêm mới một khách hàng, trước khi thêm kiểm tra xem MAKH đã tồn tại hay không, và MAVT đã tồn tại trong bảng VAITRO chưa
CREATE PROC PRC_ThemMoi_KhachHang
(
    @MAKH CHAR(8),
    @TENKH NVARCHAR(50),
    @GIOITINH NVARCHAR(3),
    @NGAYSINH DATE,
    @CCCD CHAR(12),
    @NGAYCAP DATE,
    @QUOCTICH NVARCHAR(50),
    @SODT CHAR(10),
    @EMAIL NVARCHAR(50),
    @DIACHI NVARCHAR(100),
    @PASSWORD NVARCHAR(50),
    @NGAYTAOTK DATE,
    @MAVT CHAR(8)
) AS
BEGIN
    IF EXISTS (SELECT 1 FROM KHACHHANG WHERE MAKH = @MAKH)
    BEGIN
        PRINT N'Mã khách hàng đã tồn tại.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM VAITRO WHERE MAVT = @MAVT)
    BEGIN
        PRINT N'Mã vai trò không tồn tại.';
        RETURN;
    END
    INSERT INTO KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT)
    VALUES (@MAKH, @TENKH, @GIOITINH, @NGAYSINH, @CCCD, @NGAYCAP, @QUOCTICH, @SODT, @EMAIL, @DIACHI, @PASSWORD, @NGAYTAOTK, @MAVT);
END

GO
EXEC PRC_ThemMoi_KhachHang 'KH000001', N'Nguyễn Văn A', N'M', '1999/01/01', '023456789012', '2020/01/01', N'Việt Nam', '0123456789', 'nva@gmail.com', N'123 Đường 456', '123456', '2020/01/01', 'VT000001';
GO

--10) Thêm mới một vé cho chuyến bay có sẵn
CREATE PROC PRC_ThemMoi_Ve
(
    @MAVE CHAR(8),
    @MAHV CHAR(8),
    @MACB CHAR(8),
    @MAHD CHAR(8),
    @GIAVE INT,
    @GHE CHAR(3)
) AS
BEGIN
    IF EXISTS (SELECT 1 FROM VE WHERE MAVE = @MAVE)
    BEGIN
        PRINT N'Mã vé đã tồn tại.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM HANGVE WHERE MAHV = @MAHV)
    BEGIN
        PRINT N'Mã hạng vé không tồn tại.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM CHUYENBAY WHERE MACB = @MACB)
    BEGIN
        PRINT N'Mã chuyến bay không tồn tại.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM CHUYENBAY WHERE MAHD = @MAHD)
    BEGIN
        PRINT N'Mã hóa đơn không tồn tại.';
        RETURN;
    END
    INSERT INTO VE (MAVE, MAHV, MACB, MAHD, GIAVE, GHE)
    VALUES (@MAVE, @MAHV, @MACB, @MAHD, @GIAVE, @GHE);
END

GO
EXEC PRC_ThemMoi_Ve 'ABCD1234', 'F', 'AC 133', null, 1000000, '1'
GO

--11) Thêm mới một hoá đơn 
CREATE PROC PRC_ThemMoi_HoaDon
(
    @MAHD CHAR(8),
    @MANV CHAR(8),
    @MAKH CHAR(8),
    @MAVE CHAR(8),
    @TINHTRANG INT
) AS
BEGIN
    IF EXISTS (SELECT 1 FROM HOADON WHERE MAHD = @MAHD)
    BEGIN
        PRINT N'Mã hoá đơn đã tồn tại.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MAKH = @MAKH)
    BEGIN
        PRINT N'Mã khách hàng không tồn tại.';
        RETURN;
    END
    IF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = @MANV)
    BEGIN
        PRINT N'Mã nhân viên không tồn tại.';
        RETURN;
    END
    IF EXISTS (SELECT 1 FROM VE WHERE MAVE = @MAVE AND MAHD IS NOT NULL)
    BEGIN
        PRINT N'Vé đã được mua.';
        RETURN;
    END
    INSERT INTO HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG)
    VALUES (@MAHD, @MANV, @MAKH, GETDATE(), @TINHTRANG);
    UPDATE VE
    SET MAHD = @MAHD
    WHERE MAVE = @MAVE;
END

GO
EXEC PRC_ThemMoi_HoaDon '00000001', 'NV078538', 'KH496697', 'ABCD1234', 1;
GO

--13) Cập nhật lại giá vé
CREATE PROC PRC_CapNhat_GiaVe
(
    @MAVE CHAR(8),
    @GIAVE INT
) AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM VE WHERE MAVE = @MAVE)
    BEGIN
        PRINT N'Mã vé không tồn tại.';
        RETURN;
    END
    UPDATE VE
    SET GIAVE = @GIAVE
    WHERE MAVE = @MAVE;
END

GO
EXEC PRC_CapNhat_GiaVe 'ABCD1234', 2000000;
GO
