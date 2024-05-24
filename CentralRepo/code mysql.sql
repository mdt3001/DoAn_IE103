CREATE DATABASE QUANLYCHUYENBAY;

USE QUANLYCHUYENBAY;

SET GLOBAL log_bin_trust_function_creators = 1;

CREATE TABLE MAYBAY (
    MAMB CHAR(8) PRIMARY KEY,
    TENMAYBAY VARCHAR(40) NOT NULL,
    HANGSANXUAT VARCHAR(50) NOT NULL,
    SOGHETHUONG INT NOT NULL,
    SOGHEVIP INT NOT NULL
);

CREATE TABLE SANBAY (
    MASB CHAR(3) PRIMARY KEY,
    TENSB VARCHAR(40) NOT NULL,
    DIADIEM VARCHAR(40) NOT NULL
);

CREATE TABLE TUYENBAY (
    MATB CHAR(8) PRIMARY KEY,
    MASBDI CHAR(3),
    MASBDEN CHAR(3),
    FOREIGN KEY (MASBDI) REFERENCES SANBAY(MASB),
    FOREIGN KEY (MASBDEN) REFERENCES SANBAY(MASB)
);

CREATE TABLE CHUYENBAY (
    MACB CHAR(8) PRIMARY KEY,
    MATB CHAR(8),
    MAMB CHAR(8),
    NGAYKHOIHANH DATE NOT NULL,
    GIOKHOIHANH TIME NOT NULL,
    THOIGIANDUKIEN TIME NOT NULL,
    GIOHACANH TIME,
    SOGHEHANGTHUONGCONLAI INT,
    SOGHEHANGVIPCONLAI INT,
    FOREIGN KEY (MATB) REFERENCES TUYENBAY(MATB),
    FOREIGN KEY (MAMB) REFERENCES MAYBAY(MAMB)
);

CREATE TABLE VAITRO (
    MAVT CHAR(8) PRIMARY KEY,
    TENVAITRO VARCHAR(50) NOT NULL
);

CREATE TABLE NHANVIEN (
    MANV CHAR(8) PRIMARY KEY,
    TENNV VARCHAR(30) NOT NULL,
    DIACHI CHAR(50) NOT NULL,
    SODT VARCHAR(10) UNIQUE,
    NGAYSINH DATE NOT NULL,
    NGAYVAOLAM DATE NOT NULL,
    GIOITINH CHAR(3) NOT NULL,
    EMAIL VARCHAR(50) UNIQUE,
    PASSWORD VARCHAR(256) NOT NULL,
    NGAYTAOTK DATETIME NOT NULL,
    MAVT CHAR(8),
    FOREIGN KEY (MAVT) REFERENCES VAITRO(MAVT)
);

CREATE TABLE KHACHHANG (
    MAKH CHAR(8) PRIMARY KEY,
    TENKH VARCHAR(30) NOT NULL,
    GIOITINH CHAR(3) NOT NULL,
    NGAYSINH DATE NOT NULL,
    CCCD VARCHAR(13) UNIQUE,
    NGAYCAP DATE,
    QUOCTICH VARCHAR(30) NOT NULL,
    SODT VARCHAR(10) UNIQUE,
    EMAIL VARCHAR(50) UNIQUE,
    DIACHI CHAR(50) NOT NULL,
    PASSWORD VARCHAR(256) NOT NULL,
    NGAYTAOTK DATETIME NOT NULL,
    MAVT CHAR(8),
    FOREIGN KEY (MAVT) REFERENCES VAITRO(MAVT)
);

CREATE TABLE HOADON (
    MAHD CHAR(8) PRIMARY KEY,
    MANV CHAR(8),
    MAKH CHAR(8),
    NGAYLAP DATE NOT NULL,
    SOVE INT,
    THANHTIEN DECIMAL(10,2),
    TINHTRANG INT,
    FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV),
    FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)
);

CREATE TABLE HANGVE (
    MAHV CHAR(8) PRIMARY KEY,
    TENHANGVE VARCHAR(20) NOT NULL
);

CREATE TABLE VE (
    MAVE CHAR(8) PRIMARY KEY,
    MAHV CHAR(8),
    MACB CHAR(8),
    MAHD CHAR(8),
    GHE CHAR(3) NOT NULL,
    GIAVE DECIMAL(19,4) NOT NULL,
    FOREIGN KEY (MAHV) REFERENCES HANGVE(MAHV),
    FOREIGN KEY (MACB) REFERENCES CHUYENBAY(MACB),
    FOREIGN KEY (MAHD) REFERENCES HOADON(MAHD)
);

-- Thêm ràng buộc
ALTER TABLE NHANVIEN ADD CONSTRAINT CHK_SODT CHECK (SODT LIKE '0%');
ALTER TABLE NHANVIEN ADD CONSTRAINT CHK_NGAYVAOLAM_NGAYSINH CHECK (NGAYVAOLAM > NGAYSINH);
ALTER TABLE NHANVIEN ADD CONSTRAINT CHK_NGAYTAOTK CHECK (NGAYTAOTK >= NGAYVAOLAM);

ALTER TABLE KHACHHANG ADD CONSTRAINT CHK_NGAYCAP_NGAYSINH CHECK (NGAYCAP > NGAYSINH);
ALTER TABLE KHACHHANG ADD CONSTRAINT CHK_SODT_KH CHECK (SODT LIKE '0%');

ALTER TABLE VE ADD CONSTRAINT CHK_GIAVE CHECK (GIAVE >=0);
ALTER TABLE VE ADD CONSTRAINT CHK_MACB_GHE UNIQUE (MACB,GHE);

ALTER TABLE CHUYENBAY ADD CONSTRAINT CHK_SOGHEHANGTHUONGCONLAI CHECK (SOGHEHANGTHUONGCONLAI >= 0);
ALTER TABLE CHUYENBAY ADD CONSTRAINT CHK_SOGHEHANGVIPCONLAI CHECK (SOGHEHANGVIPCONLAI >= 0);

ALTER TABLE MAYBAY ADD CONSTRAINT CHK_SOGHETHUONG CHECK (SOGHETHUONG >= 0);
ALTER TABLE MAYBAY ADD CONSTRAINT CHK_SOGHEVIP CHECK (SOGHEVIP >= 0);

ALTER TABLE HOADON ADD CONSTRAINT CHK_TINHTRANG CHECK (TINHTRANG = 0 OR TINHTRANG = 1);

ALTER TABLE TUYENBAY ADD CONSTRAINT CHK_MASBDI_MASBDEN CHECK (MASBDI <> MASBDEN);

-- Thêm salt vào bảng khách hàng & nhân viên để mã hóa
ALTER TABLE NHANVIEN
ADD COLUMN SALT VARCHAR(32);
ALTER TABLE KHACHHANG
ADD COLUMN SALT VARCHAR(32);


-- FUNCTION
-- Function đếm số lượng khách hàng theo tháng trong năm
DELIMITER //
CREATE FUNCTION FUNC_DEM_SLKHDK_THEOTHANG(in_p_month INT, in_p_year INT)
RETURNS INT
BEGIN
    DECLARE v_SLKH INT;
    SELECT COUNT(*) INTO v_SLKH
    FROM KHACHHANG
    WHERE MONTH(NGAYTAOTK) = in_p_month AND YEAR(NGAYTAOTK) = in_p_year;
    RETURN v_SLKH;
END;//
DELIMITER ;

-- Function đếm số lượng chuyến bay theo tháng
DELIMITER //
CREATE FUNCTION FUNC_DEM_SLCB_THEOTHANG(in_p_month INT, in_p_year INT)
RETURNS INT
BEGIN
    DECLARE v_SLCB INT;
    SELECT COUNT(*) INTO v_SLCB
    FROM CHUYENBAY
    WHERE MONTH(NGAYKHOIHANH) = in_p_month AND YEAR(NGAYKHOIHANH) = in_p_year;
    RETURN v_SLCB;
END;//
DELIMITER ;

-- Function tính doanh thu theo ngày / tháng / năm
DELIMITER //
CREATE FUNCTION FUNC_DOANHTHU(in_p_day INT, in_p_month INT, in_p_year INT)
RETURNS DECIMAL(10,2)
BEGIN 
    DECLARE v_DOANHTHU DECIMAL(10,2);
    IF (in_p_day IS NOT NULL AND in_p_month IS NULL) OR
       (in_p_month IS NOT NULL AND in_p_year IS NULL) THEN
        SET v_DOANHTHU = NULL;
        RETURN v_DOANHTHU;
    END IF;
    
    IF (in_p_day IS NOT NULL) THEN
        SELECT COALESCE(SUM(HD.THANHTIEN), 0) INTO v_DOANHTHU
        FROM HOADON HD
        WHERE DAY(HD.NGAYLAP) = in_p_day
            AND MONTH(HD.NGAYLAP) = in_p_month
            AND YEAR(HD.NGAYLAP) = in_p_year
            AND TINHTRANG = 1;
    ELSEIF (in_p_month IS NOT NULL) THEN
        SELECT COALESCE(SUM(HD.THANHTIEN), 0) INTO v_DOANHTHU
        FROM HOADON HD
        WHERE MONTH(HD.NGAYLAP) = in_p_month
            AND YEAR(HD.NGAYLAP) = in_p_year
            AND TINHTRANG = 1;
    ELSEIF (in_p_year IS NOT NULL) THEN
        SELECT COALESCE(SUM(HD.THANHTIEN), 0) INTO v_DOANHTHU
        FROM HOADON HD
        WHERE YEAR(HD.THANHTIEN) = in_p_year
            AND TINHTRANG = 1;
    END IF;
    
    RETURN v_DOANHTHU;
END;//
DELIMITER ;

-- Function tạo salt để hash mật khẩu
DELIMITER //
CREATE FUNCTION FUNC_SALT() RETURNS VARCHAR(10)
BEGIN
	DECLARE chars VARCHAR(255) DEFAULT 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
	DECLARE salt VARCHAR(255) DEFAULT '';
	DECLARE i INT DEFAULT 0;
	WHILE i < 10 DO
		SET salt = CONCAT(salt, SUBSTRING(chars, FLOOR(1 + RAND() * CHAR_LENGTH(chars)), 1));
		SET i = i + 1;
  END WHILE;
  RETURN salt;
END;//
DELIMITER ;

-- TRIGGER
-- Trigger kiểm tra ngày tạo tài khoản nhân viên
DELIMITER //
CREATE TRIGGER TRG_KIEMTRANGAYTAOTKNV
BEFORE INSERT ON NHANVIEN
FOR EACH ROW
BEGIN
   IF NEW.NGAYTAOTK < NEW.NGAYVAOLAM OR NEW.NGAYTAOTK > CURDATE() THEN 
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ngày tạo tài khoản không hợp lệ';
   END IF;
END;//
DELIMITER ;

-- Trigger kiểm tra ngày tạo tài khoản khách hàng
DELIMITER //
CREATE TRIGGER TRG_KIEMTRANGAYTAOTKKH
BEFORE INSERT ON KHACHHANG
FOR EACH ROW
BEGIN
   IF NEW.NGAYTAOTK > CURDATE() THEN 
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Ngày tạo tài khoản không hợp lệ';
   END IF;
END;//
DELIMITER ;

-- Trigger kiểm tra độ tuổi của nhân viên (lớn hơn 18)
DELIMITER //
CREATE TRIGGER TRG_KIEMTRATUOI
BEFORE INSERT ON NHANVIEN
FOR EACH ROW
BEGIN
   IF TIMESTAMPDIFF(YEAR, NEW.NGAYSINH, CURDATE()) < 18 THEN 
      SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Tuổi của nhân viên phải lớn hơn hoặc bằng 18.';
   END IF;
END;//
DELIMITER ;

-- Trigger tạo mã tuyến bay
DELIMITER //
CREATE TRIGGER TRG_TUDONGTAO_MATB
BEFORE INSERT ON TUYENBAY
FOR EACH ROW
BEGIN
	SET NEW.MATB = CONCAT(NEW.MASBDI, '-', NEW.MASBDEN);
END;//
DELIMITER ;

-- Trigger thêm số ghế thường và số ghế vip, giờ hạ cánh
DELIMITER //
CREATE TRIGGER TRG_SOGHECONLAI
BEFORE INSERT ON CHUYENBAY
FOR EACH ROW
BEGIN
	IF HOUR(ADDTIME(NEW.GIOKHOIHANH, NEW.THOIGIANDUKIEN)) > 24 THEN
		SET NEW.GIOHACANH = SUBTIME(ADDTIME(NEW.GIOKHOIHANH, NEW.THOIGIANDUKIEN), '24:00:00');
	ELSE
		SET NEW.GIOHACANH = ADDTIME(NEW.GIOKHOIHANH, NEW.THOIGIANDUKIEN);
	END IF;
	SET NEW.SOGHEHANGTHUONGCONLAI = (SELECT SOGHETHUONG FROM MAYBAY WHERE MAMB = NEW.MAMB);
	SET NEW.SOGHEHANGVIPCONLAI = (SELECT SOGHEVIP FROM MAYBAY WHERE MAMB = NEW.MAMB);
END;//
DELIMITER ;

-- Trigger kiểm tra vị trí ghế thường & vip hợp lệ
DELIMITER //
CREATE TRIGGER TRG_VITRIGHE
BEFORE INSERT ON VE
FOR EACH ROW
BEGIN
	DECLARE tongghevip INT;
	DECLARE tongghethuong INT;

	SELECT SOGHEVIP, SOGHETHUONG INTO tongghevip , tongghethuong FROM MAYBAY
	JOIN CHUYENBAY ON MAYBAY.MAMB = CHUYENBAY.MAMB WHERE CHUYENBAY.MACB = NEW.MACB;

	IF NEW.MAHV = 'F' AND NEW.GHE > 0 AND NEW.GHE <= tongghevip THEN
		UPDATE CHUYENBAY
		SET SOGHEHANGVIPCONLAI = SOGHEHANGVIPCONLAI - 1
		WHERE MACB = NEW.MACB;
	ELSEIF (NEW.MAHV = 'J' OR NEW.MAHV = 'W' OR NEW.MAHV = 'Y') AND NEW.GHE > tongghevip AND NEW.GHE <= (tongghevip + tongghethuong) THEN
		UPDATE CHUYENBAY
		SET SOGHEHANGTHUONGCONLAI = SOGHEHANGTHUONGCONLAI - 1
		WHERE MACB = NEW.MACB;
   ELSE
		SIGNAL SQLSTATE '45000'
		SET MESSAGE_TEXT = 'Ghế không hợp lệ.';
   END IF;
END;//
DELIMITER ;

-- Trigger cập nhật số vé và thành tiền của hóa đơn
DELIMITER //
CREATE TRIGGER TRG_CAPNHATHOADON
AFTER INSERT ON VE
FOR EACH ROW
BEGIN
   UPDATE HOADON
   SET SOVE = (SELECT COUNT(*) FROM VE WHERE MAHD = NEW.MAHD),
       THANHTIEN = (SELECT SUM(GIAVE) FROM VE WHERE MAHD = NEW.MAHD)
   WHERE MAHD = NEW.MAHD;
END;//
DELIMITER ;


-- Trigger thêm salt và mã hóa mật khẩu cho nhân viên
DELIMITER //
CREATE TRIGGER TRG_MAHOANHANVIEN
BEFORE INSERT ON NHANVIEN
FOR EACH ROW
BEGIN
    DECLARE in_SALT VARCHAR(10);
    DECLARE hash_PASSWORD VARCHAR(256);
    SET in_SALT = FUNC_SALT();
    SET NEW.SALT = in_SALT;
    SET NEW.PASSWORD = SHA2(CONCAT(NEW.PASSWORD, in_SALT), 256);
END;//
DELIMITER ;

-- Trigger thêm salt và mã hóa mật khẩu cho khách hàng
DELIMITER //
CREATE TRIGGER TRG_MAHOAKHACHHANG
BEFORE INSERT ON KHACHHANG
FOR EACH ROW
BEGIN
    DECLARE in_SALT VARCHAR(10);
    DECLARE hash_PASSWORD VARCHAR(256);
    SET in_SALT = FUNC_SALT();
    SET NEW.SALT = in_SALT;
    SET NEW.PASSWORD = SHA2(CONCAT(NEW.PASSWORD, in_SALT), 256);
END;//
DELIMITER ;

-- PROCEDURE
-- Procedure hiển thị danh sách khách hàng
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_KhachHang()
BEGIN
    SELECT * FROM KHACHHANG;
END;//
DELIMITER ;

-- Procedure hiển thị danh sách nhân viên
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_NhanVien()
BEGIN
    SELECT * FROM NHANVIEN;
END;//
DELIMITER ;

-- Procedure hiển thị danh sách các hoá đơn do 1 nhân viên đã tạo
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_HoaDon_NhanVien_DaTao(IN in_MANV CHAR(8))
BEGIN 
    SELECT * FROM HOADON WHERE MANV = in_MANV;
END;//
DELIMITER ;

-- Procedure hiển thị danh sách các chuyến bay theo ngày
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_ChuyenBay_TheoNgay(IN in_NGAYKHOIHANH DATE)
BEGIN
    SELECT * FROM CHUYENBAY WHERE NGAYKHOIHANH = in_NGAYKHOIHANH;
END;//
DELIMITER ;

-- Procedure thêm mới một nhân viên, trước khi thêm kiểm tra xem MANV đã tồn tại hay không, và MAVT đã tồn tại trong bảng VAITRO chưa
DELIMITER //
CREATE PROCEDURE PRC_ThemMoi_NhanVien(IN in_MANV CHAR(8), IN in_TENNV VARCHAR(50), IN in_DIACHI CHAR(50), IN in_SODT VARCHAR(10), IN in_NGAYSINH DATE, IN in_NGAYVAOLAM DATE, IN in_GIOITINH CHAR(3), IN in_EMAIL VARCHAR(50), IN in_PASSWORD VARCHAR(50), IN in_NGAYTAOTK DATETIME, IN in_MAVT CHAR(8))
BEGIN
    IF EXISTS (SELECT * FROM NHANVIEN WHERE MANV = in_MANV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã nhân viên đã tồn tại';
    ELSEIF NOT EXISTS (SELECT * FROM VAITRO WHERE MAVT = in_MAVT) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã vai trò không tồn tại';
    ELSE
        INSERT INTO NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) VALUES (in_MANV, in_TENNV, in_DIACHI, in_SODT, in_NGAYSINH, in_NGAYVAOLAM, in_GIOITINH, in_EMAIL, in_PASSWORD, in_NGAYTAOTK, in_MAVT);
    END IF;
END;//
DELIMITER ;

-- Procedure thêm mới một chuyến bay 
DELIMITER //
CREATE PROCEDURE PRC_ThemMoi_ChuyenBay(IN in_MACB CHAR(8), IN in_MATB CHAR(8), IN in_MAMB CHAR(8), IN in_NGAYKHOIHANH DATE, IN in_GIOKHOIHANH TIME, IN in_THOIGIANDUKIEN TIME)
BEGIN
    IF EXISTS (SELECT * FROM CHUYENBAY WHERE MACB = in_MACB) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã chuyến bay đã tồn tại';
    ELSEIF NOT EXISTS (SELECT * FROM TUYENBAY WHERE MATB = in_MATB) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã tuyến bay không tồn tại';
    ELSEIF NOT EXISTS (SELECT * FROM MAYBAY WHERE MAMB = in_MAMB) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã máy bay không tồn tại';
    ELSE
        INSERT INTO CHUYENBAY(MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) VALUES(in_MACB, in_MATB, in_MAMB, in_NGAYKHOIHANH, in_GIOKHOIHANH, in_THOIGIANDUKIEN);
    END IF;
END;//
DELIMITER ;

-- Procedure tính tổng tiền đã thanh toán thành công của một khách hàng 
DELIMITER //
CREATE PROCEDURE PRC_TongTienDaMua(IN in_MAKH CHAR(8), OUT TONGTIENDATHANHTOAN DECIMAL(10,2))
BEGIN
    SELECT SUM(THANHTIEN) INTO TONGTIENDATHANHTOAN FROM HOADON WHERE MAKH = in_MAKH AND TINHTRANG = 1;
END;//
DELIMITER ;

-- Procedure hiển thị danh sách các chuyến bay
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_ChuyenBay()
BEGIN
    SELECT * FROM CHUYENBAY;
END;//
DELIMITER ;

-- Procedure hiển thị danh sách các hoá đơn đã thanh toán của 1 khách hàng
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_HoaDon_KhachHang_DaThanhToan(IN in_MAKH CHAR(8))
BEGIN
    SELECT * FROM HOADON
    WHERE TINHTRANG = '1' AND MAKH = in_MAKH;
END;//
DELIMITER ;

-- Procedure hiển thị danh sách các vé theo mã chuyến bay
DELIMITER //
CREATE PROCEDURE PRC_DanhSach_Ve_Theo_MACB(IN in_MACB CHAR(8))
BEGIN
    SELECT * FROM VE
    WHERE MACB = in_MACB;
END;//
DELIMITER ;

-- Procedure thêm mới một khách hàng, trước khi thêm kiểm tra xem MAKH đã tồn tại hay không, và MAVT đã tồn tại trong bảng VAITRO chưa
DELIMITER //
CREATE PROCEDURE PRC_ThemMoi_KhachHang(IN in_MAKH CHAR(8), IN in_TENKH NVARCHAR(50), IN in_GIOITINH NVARCHAR(3), IN in_NGAYSINH DATE, IN in_CCCD CHAR(12), IN in_NGAYCAP DATE, IN in_QUOCTICH NVARCHAR(50), IN in_SODT CHAR(10), IN in_EMAIL NVARCHAR(50), IN in_DIACHI NVARCHAR(100), IN in_PASSWORD NVARCHAR(50), IN in_NGAYTAOTK DATE, IN in_MAVT CHAR(8))
BEGIN
    IF EXISTS (SELECT 1 FROM KHACHHANG WHERE MAKH = in_MAKH) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã khách hàng đã tồn tại.';
    ELSEIF NOT EXISTS (SELECT 1 FROM VAITRO WHERE MAVT = in_MAVT) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã vai trò không tồn tại.';
    ELSE
        INSERT INTO KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT)
        VALUES (in_MAKH, in_TENKH, in_GIOITINH, in_NGAYSINH, in_CCCD, in_NGAYCAP, in_QUOCTICH, in_SODT, in_EMAIL, in_DIACHI, in_PASSWORD, in_NGAYTAOTK, in_MAVT);
    END IF;
END;//
DELIMITER ;

-- Procedure thêm mới một vé cho chuyến bay có sẵn
DELIMITER //
CREATE PROCEDURE PRC_ThemMoi_Ve(IN in_MAVE CHAR(8), IN in_MAHV CHAR(8), IN in_MACB CHAR(8), IN in_MAHD CHAR(8), IN in_GIAVE INT, IN in_GHE CHAR(3))
BEGIN
    IF EXISTS (SELECT 1 FROM VE WHERE MAVE = in_MAVE) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã vé đã tồn tại.';
    ELSEIF NOT EXISTS (SELECT 1 FROM HANGVE WHERE MAHV = in_MAHV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã hạng vé không tồn tại.';
    ELSEIF NOT EXISTS (SELECT 1 FROM CHUYENBAY WHERE MACB = in_MACB) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã chuyến bay không tồn tại.';
    ELSEIF NOT EXISTS (SELECT 1 FROM HOADON WHERE MAHD = in_MAHD) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã hóa đơn không tồn tại.';
    ELSE
        INSERT INTO VE (MAVE, MAHV, MACB, MAHD, GIAVE, GHE)
        VALUES (in_MAVE, in_MAHV, in_MACB, in_MAHD, in_GIAVE, in_GHE);
    END IF;
END;//
DELIMITER ;

-- Procedure thêm mới một hoá đơn 
DELIMITER //
CREATE PROCEDURE PRC_ThemMoi_HoaDon(IN in_MAHD CHAR(8), IN in_MANV CHAR(8), IN in_MAKH CHAR(8), IN in_MAVE CHAR(8), IN in_TINHTRANG INT)
BEGIN
    IF EXISTS (SELECT 1 FROM HOADON WHERE MAHD = in_MAHD) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã hoá đơn đã tồn tại.';
    ELSEIF NOT EXISTS (SELECT 1 FROM KHACHHANG WHERE MAKH = in_MAKH) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã khách hàng không tồn tại.';
    ELSEIF NOT EXISTS (SELECT 1 FROM NHANVIEN WHERE MANV = in_MANV) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã nhân viên không tồn tại.';
    ELSEIF EXISTS (SELECT 1 FROM VE WHERE MAVE = in_MAVE AND MAHD IS NOT NULL) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Vé đã được mua.';
    ELSE
        INSERT INTO HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG)
        VALUES (in_MAHD, in_MANV, in_MAKH, CURDATE(), in_TINHTRANG);
        UPDATE VE
        SET MAHD = in_MAHD
        WHERE MAVE = in_MAVE;
    END IF;
END;//
DELIMITER ;

-- Procedure cập nhật lại giá vé
DELIMITER //
CREATE PROCEDURE PRC_CapNhat_GiaVe(IN in_MAVE CHAR(8), IN in_GIAVE INT)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM VE WHERE MAVE = in_MAVE) THEN
		SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Mã vé không tồn tại.';
    ELSE
        UPDATE VE
        SET GIAVE = in_GIAVE
        WHERE MAVE = in_MAVE;
    END IF;
END;//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE PRC_TIM_CHUYENBAY (IN diem_di VARCHAR(40), IN diem_den VARCHAR(40), IN ngay_di DATE)
BEGIN
    DECLARE masbdi CHAR(8);
    DECLARE masbden CHAR(8);

    -- Error handling for missing departure airport
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET masbdi = NULL;
        SELECT MASB INTO masbdi
        FROM SANBAY
        WHERE DIADIEM = diem_di
        LIMIT 1;
    END;

    -- Error handling for missing destination airport
    BEGIN
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET masbden = NULL;
        SELECT MASB INTO masbden
        FROM SANBAY
        WHERE DIADIEM = diem_den
        LIMIT 1;
    END;

    IF masbdi IS NOT NULL AND masbden IS NOT NULL THEN
        SELECT CB.MACB, NGAYKHOIHANH, GIOKHOIHANH, GIOHACANH, GIAVE, TENHANGVE
        FROM CHUYENBAY CB 
        JOIN TUYENBAY TB ON CB.MATB = TB.MATB 
        JOIN VE ON CB.MACB = VE.MACB 
        JOIN HANGVE HV ON VE.MAHV = HV.MAHV
        WHERE TB.MASBDI = masbdi AND TB.MASBDEN = masbden AND CB.NGAYKHOIHANH = ngay_di;
    ELSE
        SELECT 'Không tìm thấy chuyến bay.' AS message;
    END IF;
END;//
DELIMITER ;

-- THÊM DỮ LIỆU
-- Thêm dữ liệu cho bảng SANBAY
insert into SANBAY (MASB, TENSB, DIADIEM) values ('FCM', 'Flying Cloud Airport', 'Minneapolis');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('COF', 'Patrick Air Force Base', 'Cocoa Beach');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('GAV', 'Gag Island Airport', 'Gag Island');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('BKD', 'Stephens County Airport', 'Breckenridge');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('CNW', 'TSTC Waco Airport', 'Waco');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('ERG', 'Yerbogachen Airport', 'Erbogachen');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('LDS', 'Lindu Airport', 'Yichun');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('MMH', 'Mammoth Yosemite Airport', 'Mammoth Lakes');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SWV', 'Shikarpur Airport', 'Shikarpur');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('NCE', 'Nice-Côte d''Azur Airport', 'Nice');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('YWB', 'Kangiqsujuaq (Wakeham Bay) Airport', 'Kangiqsujuaq');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('HGU', 'Mount Hagen Kagamuga Airport', 'Mount Hagen');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('FRO', 'Florø Airport', 'Florø');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('ORN', 'Es Senia Airport', 'Oran');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('ABK', 'Kabri Dehar Airport', 'Kabri Dehar');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SQO', 'Storuman Airport', 'Storuman');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('BOT', 'Bosset Airport', 'Bosset');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('BLD', 'Boulder City Municipal Airport', 'Boulder City');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('BBW', 'Broken Bow Municipal Airport', 'Broken Bow');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('FDE', 'Førde Airport', 'Førde');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('PPU', 'Hpapun Airport', 'Pa Pun');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SUT', 'Sumbawanga Airport', 'Sumbawanga');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('NKD', 'Sinak Airport', 'Sinak');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('NLS', 'Nicholson Airport', 'Nicholson');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('CKE', 'Lampson Field', 'Lakeport');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('WLW', 'Willows Glenn County Airport', 'Willows');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('TDA', 'Trinidad Airport', 'Trinidad');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('TAB', 'Tobago-Crown Point Airport', 'Scarborough');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('FRN', 'Bryant Army Heliport', 'Fort Richardson(Anchorage)');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('TRG', 'Tauranga Airport', 'Tauranga');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SYB', 'Seal Bay Seaplane Base', 'Seal Bay');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('FRQ', 'Feramin Airport', 'Feramin');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('KDP', 'Kandep Airport', 'Kandep');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('ARS', 'Aragarças Airport', 'Aragarças');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('KSL', 'Kassala Airport', 'Kassala');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SAF', 'Santa Fe Municipal Airport', 'Santa Fe');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('GOB', 'Robe Airport', 'Goba');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('PTT', 'Pratt Regional Airport', 'Pratt');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SQZ', 'RAF Scampton', 'Scampton');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('OKJ', 'Okayama Airport', 'Okayama City');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('URC', 'Ürümqi Diwopu International Airport', 'Ürümqi');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('JRB', 'Downtown-Manhattan/Wall St Heliport', 'New York');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('TUA', 'Teniente Coronel Luis a Mantilla Airport', 'Tulcán');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('AMA', 'Amarillo International Airport', 'Amarillo');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('PJB', 'Payson Airport', 'Payson');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('MVK', 'Mulka Airport', 'Mulka');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('MGR', 'Moultrie Municipal Airport', 'Moultrie');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('MGD', 'Magdalena Airport', 'Magdalena');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('SKQ', 'Sekakes Airport', 'Sekakes');
insert into SANBAY (MASB, TENSB, DIADIEM) values ('MBX', 'Maribor Airport', 'Maribor');

-- Thêm dữ liệu cho bảng TUYENBAY
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BBW-SUT', 'BBW', 'SUT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NLS-BOT', 'NLS', 'BOT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BBW-SQZ', 'BBW', 'SQZ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GAV-ORN', 'GAV', 'ORN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('COF-TRG', 'COF', 'TRG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-ORN', 'PPU', 'ORN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('HGU-CKE', 'HGU', 'CKE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-URC', 'MBX', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-WLW', 'SAF', 'WLW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-SQZ', 'CKE', 'SQZ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KSL-URC', 'KSL', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-WLW', 'MBX', 'WLW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SWV-TDA', 'SWV', 'TDA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FDE-FRQ', 'FDE', 'FRQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-NCE', 'MGR', 'NCE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('AMA-TRG', 'AMA', 'TRG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FCM-AMA', 'FCM', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BLD-CNW', 'BLD', 'CNW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KSL-SWV', 'KSL', 'SWV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-BKD', 'PPU', 'BKD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ORN-BKD', 'ORN', 'BKD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BBW-AMA', 'BBW', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('OKJ-CNW', 'OKJ', 'CNW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRO-COF', 'FRO', 'COF');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FDE-NCE', 'FDE', 'NCE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('OKJ-SQO', 'OKJ', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-BBW', 'SAF', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BKD-GAV', 'BKD', 'GAV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRQ-SYB', 'FRQ', 'SYB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ERG-TUA', 'ERG', 'TUA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('LDS-FCM', 'LDS', 'FCM');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PJB-MBX', 'PJB', 'MBX');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ORN-SUT', 'ORN', 'SUT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ORN-SAF', 'ORN', 'SAF');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SKQ-JRB', 'SKQ', 'JRB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('URC-PTT', 'URC', 'PTT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MMH-SQO', 'MMH', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PTT-FDE', 'PTT', 'FDE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KSL-ARS', 'KSL', 'ARS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FCM-TAB', 'FCM', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MVK-TRG', 'MVK', 'TRG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRO-SAF', 'FRO', 'SAF');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NLS-FRN', 'NLS', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NKD-FRN', 'NKD', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-BLD', 'SAF', 'BLD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TUA-OKJ', 'TUA', 'OKJ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-BOT', 'TAB', 'BOT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ABK-MVK', 'ABK', 'MVK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GOB-CKE', 'GOB', 'CKE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NLS-TAB', 'NLS', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-AMA', 'TAB', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRN-TDA', 'FRN', 'TDA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-SWV', 'PPU', 'SWV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('HGU-MVK', 'HGU', 'MVK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('YWB-FRO', 'YWB', 'FRO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('URC-WLW', 'URC', 'WLW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KSL-BBW', 'KSL', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-PJB', 'MGR', 'PJB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PJB-BKD', 'PJB', 'BKD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-CNW', 'ARS', 'CNW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BLD-GAV', 'BLD', 'GAV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ABK-TAB', 'ABK', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GOB-MGR', 'GOB', 'MGR');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRO-SKQ', 'FRO', 'SKQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-JRB', 'PPU', 'JRB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-MMH', 'TAB', 'MMH');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-MVK', 'MGR', 'MVK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-BBW', 'ARS', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-PPU', 'WLW', 'PPU');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CNW-ABK', 'CNW', 'ABK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-YWB', 'SAF', 'YWB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGD-SUT', 'MGD', 'SUT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-SUT', 'TAB', 'SUT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-KSL', 'TRG', 'KSL');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SYB-TDA', 'SYB', 'TDA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KDP-WLW', 'KDP', 'WLW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NCE-FRN', 'NCE', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BLD-ERG', 'BLD', 'ERG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SUT-URC', 'SUT', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-SAF', 'CKE', 'SAF');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KSL-SUT', 'KSL', 'SUT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BOT-PPU', 'BOT', 'PPU');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FDE-MBX', 'FDE', 'MBX');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PTT-FRO', 'PTT', 'FRO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ERG-SQZ', 'ERG', 'SQZ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ERG-SQO', 'ERG', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ABK-FCM', 'ABK', 'FCM');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-SKQ', 'CKE', 'SKQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ABK-LDS', 'ABK', 'LDS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TUA-NCE', 'TUA', 'NCE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-SWV', 'CKE', 'SWV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KDP-AMA', 'KDP', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ORN-NCE', 'ORN', 'NCE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-FCM', 'PPU', 'FCM');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('COF-BBW', 'COF', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-SKQ', 'ARS', 'SKQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NKD-BLD', 'NKD', 'BLD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BKD-TRG', 'BKD', 'TRG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BKD-MVK', 'BKD', 'MVK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-TDA', 'SAF', 'TDA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ABK-BKD', 'ABK', 'BKD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-URC', 'WLW', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SWV-NLS', 'SWV', 'NLS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRO-PTT', 'FRO', 'PTT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FCM-SWV', 'FCM', 'SWV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FCM-SQO', 'FCM', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-ABK', 'MBX', 'ABK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BOT-LDS', 'BOT', 'LDS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SQO-LDS', 'SQO', 'LDS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-KSL', 'CKE', 'KSL');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TDA-SQO', 'TDA', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ABK-BBW', 'ABK', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('LDS-ARS', 'LDS', 'ARS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SWV-MBX', 'SWV', 'MBX');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('HGU-TUA', 'HGU', 'TUA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CNW-SQZ', 'CNW', 'SQZ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PTT-BBW', 'PTT', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BOT-ORN', 'BOT', 'ORN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('AMA-NCE', 'AMA', 'NCE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGD-ABK', 'MGD', 'ABK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('OKJ-PJB', 'OKJ', 'PJB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SUT-OKJ', 'SUT', 'OKJ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-CKE', 'TRG', 'CKE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-BOT', 'WLW', 'BOT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-FRQ', 'CKE', 'FRQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-URC', 'TAB', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SQO-BBW', 'SQO', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KDP-ORN', 'KDP', 'ORN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ORN-FRN', 'ORN', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NCE-PPU', 'NCE', 'PPU');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-AMA', 'TRG', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KDP-JRB', 'KDP', 'JRB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GOB-SQO', 'GOB', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SWV-FRQ', 'SWV', 'FRQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MMH-SAF', 'MMH', 'SAF');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TDA-LDS', 'TDA', 'LDS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BBW-TAB', 'BBW', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SWV-TUA', 'SWV', 'TUA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PTT-KSL', 'PTT', 'KSL');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SQO-BOT', 'SQO', 'BOT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TUA-BBW', 'TUA', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SQZ-NLS', 'SQZ', 'NLS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-KDP', 'TRG', 'KDP');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('JRB-MBX', 'JRB', 'MBX');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-MGD', 'MGR', 'MGD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SKQ-GAV', 'SKQ', 'GAV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ERG-ORN', 'ERG', 'ORN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FRN-PTT', 'FRN', 'PTT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BLD-PTT', 'BLD', 'PTT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TUA-SWV', 'TUA', 'SWV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NCE-SQZ', 'NCE', 'SQZ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('COF-AMA', 'COF', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SYB-ERG', 'SYB', 'ERG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-ERG', 'TRG', 'ERG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NCE-SWV', 'NCE', 'SWV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('LDS-YWB', 'LDS', 'YWB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KDP-FRN', 'KDP', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-FRQ', 'TAB', 'FRQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NCE-HGU', 'NCE', 'HGU');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-KSL', 'MGR', 'KSL');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-BKD', 'SAF', 'BKD');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SWV-HGU', 'SWV', 'HGU');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BOT-FRQ', 'BOT', 'FRQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-SKQ', 'TAB', 'SKQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GAV-LDS', 'GAV', 'LDS');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-TAB', 'WLW', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-FCM', 'WLW', 'FCM');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('NCE-SQO', 'NCE', 'SQO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('HGU-GAV', 'HGU', 'GAV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-ERG', 'WLW', 'ERG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SYB-BBW', 'SYB', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-JRB', 'ARS', 'JRB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('COF-URC', 'COF', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-AMA', 'SAF', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-PJB', 'TAB', 'PJB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-SYB', 'MBX', 'SYB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GAV-TDA', 'GAV', 'TDA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MVK-SYB', 'MVK', 'SYB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-GAV', 'ARS', 'GAV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-PTT', 'PPU', 'PTT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('OKJ-TAB', 'OKJ', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-FRN', 'PPU', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-TUA', 'MGR', 'TUA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-SUT', 'MBX', 'SUT');

-- Thêm dữ liệu cho bảng MAYBAY
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('LPRHRT', 'Aerofox II', 'Firefly Jets', 121, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('39KBN4', 'Firestorm', 'Firefly Jets', 114, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ZS3VCX', 'Starjet', 'Sunrise Aviation', 142, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2P3YDH', 'Aerofox', 'Swiftwing Aerospace', 110, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('FG1OCD', 'Starjet', 'Sunrise Aviation', 122, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('LV92NL', 'Skyrunner', 'Skyline Aviation', 189, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('AYV3QD', 'Aerostar', 'Firefly Jets', 144, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('EKOX4T', 'Swiftwing', 'Sunrise Aviation', 177, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('Z3SU5Y', 'Starjet III', 'Thunderbird Aircraft', 113, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('TSV3RU', 'Silverhawk II', 'Wingmaster Industries', 119, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2N7ZJ0', 'Firefly', 'Bluebird Aircraft', 159, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('4ERYKN', 'Thunderbird III', 'AeroTech Industries', 158, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('G0EPZ0', 'Skydancer II', 'Swiftwing Aerospace', 109, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('DSL70C', 'Falcon', 'Phoenix Aero', 116, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2RH766', 'Skydancer II', 'Sunrise Aviation', 173, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('KZQB4V', 'Skyrunner II', 'Thunderbird Aircraft', 113, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('E0S59S', 'Swiftwing', 'Horizon Aircraft', 136, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('Y3DFPY', 'Silverhawk', 'Skybound Aviation', 179, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('V5WNES', 'Firebird', 'Horizon Aircraft', 200, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UCVW0U', 'Silverwing III', 'Golden Eagle Jets', 112, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('18E61Z', 'Falcon', 'Swiftwing Aerospace', 123, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('QMXQOC', 'Firebird', 'Wingmaster Industries', 196, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('AZFMSF', 'Airblade II', 'Silverwing Aerospace', 124, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('YL3LHE', 'Starjet II', 'Starlight Jets', 169, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ICYH4W', 'Stormrider', 'Wingmaster Industries', 102, 11);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('T8YW73', 'Skyhawk II', 'Silverwing Aerospace', 192, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('DG3X7E', 'Swiftwing', 'Starlight Jets', 180, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('KT5BZV', 'Falcon III', 'Firefly Jets', 100, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MG5VLS', 'Aerowolf', 'Sunrise Aviation', 113, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('GCQFYB', 'Swiftwing II', 'AeroStar Corporation', 151, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('9IP8S7', 'Starlight', 'Skybound Aviation', 102, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('IJ1V5W', 'Starlight', 'Skyline Aviation', 183, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('SCXEWZ', 'Silverwing', 'Starlight Jets', 148, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('EN6ZIM', 'Starjet III', 'Skyline Aviation', 180, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('JFRZKP', 'Aerostar II', 'Golden Eagle Jets', 143, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2QPOPZ', 'Aerostar', 'Silverwing Aerospace', 196, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('TYE6FV', 'Stormrider', 'AeroTech Industries', 186, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('HCTICQ', 'Aerowolf II', 'Skybound Aviation', 192, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('30GDGV', 'Aerostar', 'Swiftwing Aerospace', 111, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('4ZNGU4', 'Thunderbolt', 'Skyline Aviation', 124, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('KO910D', 'Swiftwing III', 'Phoenix Aero', 191, 11);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('7AR9EJ', 'Firestorm II', 'AeroStar Corporation', 190, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('AXNYNP', 'Stormrider II', 'Silverwing Aerospace', 171, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('N0C3YD', 'Aerowolf', 'Phoenix Aero', 146, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('KOMOZW', 'Stormrider', 'Sunrise Aviation', 169, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('AZYCMO', 'Skydancer II', 'Firefly Jets', 135, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('LVWT4Y', 'Aerofox II', 'Bluebird Aircraft', 176, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('9J6Z88', 'Starlight II', 'Swiftwing Aerospace', 159, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('A053CZ', 'Thunderbird III', 'Sunrise Aviation', 118, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('3FXGJ4', 'Swiftwing', 'Bluebird Aircraft', 183, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('BM175S', 'Wingmaster', 'Phoenix Aero', 170, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MQ57FM', 'Firefly II', 'AeroStar Corporation', 159, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('XZPZGJ', 'Wingmaster II', 'Thunderbird Aircraft', 113, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('JE82AI', 'Swiftwing II', 'Wingmaster Industries', 131, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('EN77CF', 'Wingmaster II', 'Golden Eagle Jets', 143, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MDNW6J', 'Starlight', 'Horizon Aircraft', 125, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('0RVBN8', 'Aerowolf II', 'Swiftwing Aerospace', 144, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('NMHMPN', 'Starlight', 'Skybound Aviation', 194, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('6IL98A', 'Thunderbird III', 'Starlight Jets', 187, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('TMXJZS', 'Airblade', 'Bluebird Aircraft', 137, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('8HW6Z4', 'Silverwing', 'Phoenix Aero', 113, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('87TEOL', 'Stormrider', 'Bluebird Aircraft', 177, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('G9ULBJ', 'Starjet', 'Firefly Jets', 136, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('1JLRCZ', 'Swiftwing III', 'Wingmaster Industries', 130, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('O9Q4Z1', 'Jetstream II', 'Swiftwing Aerospace', 180, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('EU16L5', 'Firefly II', 'AeroStar Corporation', 164, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('0K1VK1', 'Silverhawk II', 'Bluebird Aircraft', 125, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('YPLXH5', 'Thunderbolt', 'Bluebird Aircraft', 130, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('3346JM', 'Firestorm', 'Skybound Aviation', 193, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('S3ZJBL', 'Firefly II', 'Sunrise Aviation', 136, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('5YJ6CP', 'Starjet', 'AeroStar Corporation', 121, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('OUHHVD', 'Firestorm', 'Phoenix Aero', 162, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('1NXSL4', 'Starjet', 'Bluebird Aircraft', 146, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('XI1JDN', 'Firestorm', 'Silverwing Aerospace', 160, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UK5K2A', 'Starjet III', 'Bluebird Aircraft', 108, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('5KDI1S', 'Silverwing II', 'Thunderbird Aircraft', 170, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('B0KGFV', 'Firebird III', 'Sunrise Aviation', 122, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('I07X89', 'Aerostar', 'Swiftwing Aerospace', 196, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2SOY2C', 'Airblade II', 'Thunderbird Aircraft', 111, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('H8OKW9', 'Starlight II', 'Horizon Aircraft', 107, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('H1UGJO', 'Firebird', 'Silverwing Aerospace', 173, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('26CKWG', 'Firebird', 'Skybound Aviation', 170, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('4RGDF5', 'Stormrider II', 'Skybound Aviation', 200, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('BG87PN', 'Thunderbird', 'Horizon Aircraft', 144, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UNU0HV', 'Airblade II', 'Swiftwing Aerospace', 177, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('U3ZTV0', 'Wingmaster', 'Wingmaster Industries', 155, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('VZJ3YB', 'Thunderbird', 'AeroStar Corporation', 174, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('QVR4WK', 'Firefly II', 'Skybound Aviation', 132, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UZPB3C', 'Firebird III', 'Wingmaster Industries', 156, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('D3AUO2', 'Silverhawk II', 'Starlight Jets', 193, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('CJC722', 'Skyhawk', 'Starlight Jets', 188, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('FUHDQQ', 'Aerostar', 'Skyline Aviation', 146, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('IIFX6B', 'Wingmaster', 'Firefly Jets', 174, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('RRQUWU', 'Skydancer', 'Horizon Aircraft', 116, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('XVNM2Z', 'Stormrider II', 'Skyline Aviation', 159, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('N3IZ2K', 'Wingmaster II', 'AeroStar Corporation', 150, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('3U7010', 'Firebird III', 'Silverwing Aerospace', 111, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('H4SCFO', 'Firebird', 'Firefly Jets', 154, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('78NVH3', 'Airblade II', 'AeroStar Corporation', 200, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('8Y30PQ', 'Skyhawk III', 'Skybound Aviation', 146, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('CHUICT', 'Thunderbird II', 'Sunrise Aviation', 190, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('C1KTSU', 'Skyhawk', 'Skyline Aviation', 197, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ZG6Z15', 'Skyrunner', 'Silverwing Aerospace', 128, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('A7GGVK', 'Stormrider II', 'Skybound Aviation', 175, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('GYM1DN', 'Firestorm', 'Sunrise Aviation', 195, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('RX10GG', 'Wingmaster', 'Golden Eagle Jets', 199, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('IUQ5FT', 'Skydancer', 'Skyline Aviation', 130, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('T29JO8', 'Firefly II', 'Phoenix Aero', 193, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('O13LXR', 'Wingmaster', 'AeroTech Industries', 170, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('NAD1MG', 'Starlight', 'Firefly Jets', 122, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('XRSEF9', 'Skyhawk III', 'Phoenix Aero', 188, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('Y9XRBH', 'Aerofox', 'Thunderbird Aircraft', 199, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('OUB8PF', 'Swiftwing II', 'Phoenix Aero', 172, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MMBAP5', 'Silverwing II', 'Golden Eagle Jets', 114, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('YZ2IOF', 'Thunderbird', 'AeroStar Corporation', 194, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MOIXQS', 'Silverhawk', 'Swiftwing Aerospace', 129, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('LWLC9I', 'Thunderbolt', 'AeroStar Corporation', 134, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('H0UP9W', 'Stormrider II', 'Thunderbird Aircraft', 118, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('C6NNBB', 'Thunderbird II', 'Starlight Jets', 182, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('9XTFA1', 'Stormrider II', 'Sunrise Aviation', 169, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('NHJRHU', 'Starjet II', 'AeroStar Corporation', 150, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('RHWHO7', 'Jetstream', 'Bluebird Aircraft', 119, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('LQID94', 'Skyhawk', 'Sunrise Aviation', 163, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2S59PD', 'Thunderbolt', 'AeroStar Corporation', 142, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MTZ7CM', 'Jetstream II', 'Phoenix Aero', 171, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('D6GM2S', 'Silverhawk', 'AeroStar Corporation', 153, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('Y2MJ8M', 'Jetstream', 'Starlight Jets', 199, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ECKRZ1', 'Aerofox II', 'Sunrise Aviation', 187, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('7WGX6A', 'Falcon', 'Skyline Aviation', 163, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('O3FM61', 'Starlight', 'Firefly Jets', 143, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('EUK273', 'Swiftwing', 'Golden Eagle Jets', 187, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('QOT8IR', 'Firebird III', 'Golden Eagle Jets', 188, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('NHPAH7', 'Skyrunner II', 'Skyline Aviation', 169, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('T4QTYE', 'Jetstream II', 'AeroTech Industries', 113, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('1EU2PO', 'Wingmaster II', 'Skybound Aviation', 172, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ZGM912', 'Firestorm II', 'AeroTech Industries', 163, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('U0LG5F', 'Starlight', 'Phoenix Aero', 168, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('4LO4L2', 'Swiftwing II', 'Golden Eagle Jets', 164, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('JRNL8U', 'Wingmaster', 'Sunrise Aviation', 127, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2SOGHL', 'Firestorm', 'Skybound Aviation', 192, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('RCZ9TN', 'Thunderbolt II', 'AeroTech Industries', 188, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('1UIWGV', 'Skyhawk', 'Golden Eagle Jets', 180, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('5UAKBT', 'Thunderbird', 'Firefly Jets', 172, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('TIO4CP', 'Falcon III', 'Horizon Aircraft', 153, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('XB64ZW', 'Silverhawk', 'Bluebird Aircraft', 152, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('1SM2YE', 'Falcon III', 'Silverwing Aerospace', 141, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('Q25TS2', 'Falcon II', 'Skyline Aviation', 141, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('RKOJJ1', 'Skyrunner', 'Sunrise Aviation', 142, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('D6DECA', 'Skydancer', 'Wingmaster Industries', 188, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ZQI5XW', 'Skyrunner', 'Skyline Aviation', 172, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('YW8XMY', 'Falcon II', 'AeroTech Industries', 119, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('5FMT9Y', 'Aerowolf II', 'Wingmaster Industries', 109, 11);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('RU3GPJ', 'Wingmaster', 'Thunderbird Aircraft', 187, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('SFLJK5', 'Skydancer II', 'Wingmaster Industries', 141, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('ARLGTS', 'Thunderbolt II', 'AeroTech Industries', 177, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('NRH6XH', 'Thunderbird III', 'Thunderbird Aircraft', 139, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('CHVOIP', 'Starlight II', 'Horizon Aircraft', 131, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UVXHC2', 'Aerowolf', 'Golden Eagle Jets', 191, 11);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UQUEDL', 'Firefly', 'Swiftwing Aerospace', 106, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('D2YTNY', 'Swiftwing III', 'Phoenix Aero', 181, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UORXZ8', 'Skyhawk III', 'Thunderbird Aircraft', 169, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('PMY6HJ', 'Aerowolf II', 'AeroStar Corporation', 122, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('VBYSMO', 'Aerowolf', 'Wingmaster Industries', 112, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('6MUJKS', 'Swiftwing III', 'Swiftwing Aerospace', 120, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('WJHPSP', 'Aerofox', 'AeroStar Corporation', 141, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('70BGB5', 'Falcon III', 'Golden Eagle Jets', 108, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('G661QW', 'Aerofox II', 'Bluebird Aircraft', 134, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('JBGLF9', 'Falcon II', 'Starlight Jets', 132, 11);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('0MD3SI', 'Swiftwing II', 'Thunderbird Aircraft', 135, 11);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('LAXPQG', 'Aerostar', 'Skyline Aviation', 136, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('6Y0NQQ', 'Skyhawk III', 'Swiftwing Aerospace', 149, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('2QIMSY', 'Starjet II', 'Wingmaster Industries', 185, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MNZXQP', 'Falcon III', 'Horizon Aircraft', 198, 6);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('E6L36O', 'Falcon III', 'Firefly Jets', 150, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('SR4PW3', 'Falcon II', 'Golden Eagle Jets', 200, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('C5ZDFX', 'Firebird II', 'Starlight Jets', 199, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('7K2477', 'Skyhawk', 'AeroTech Industries', 111, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('SMFDZ5', 'Airblade II', 'AeroStar Corporation', 133, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('0GXHYZ', 'Swiftwing', 'Horizon Aircraft', 157, 14);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('U5JCIF', 'Thunderbolt', 'Horizon Aircraft', 194, 10);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('S84L1R', 'Skyrunner II', 'AeroStar Corporation', 124, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('SWO7L6', 'Silverwing III', 'Phoenix Aero', 193, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('QRSLU2', 'Falcon II', 'Firefly Jets', 175, 13);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('TDFGTJ', 'Silverhawk', 'Starlight Jets', 114, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('10SCHP', 'Skyrunner', 'Skyline Aviation', 199, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('50KB09', 'Silverwing', 'AeroTech Industries', 122, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('GPMGQ9', 'Airblade II', 'Thunderbird Aircraft', 130, 12);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('I0G60P', 'Thunderbird II', 'Silverwing Aerospace', 185, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('X947YS', 'Skydancer', 'Swiftwing Aerospace', 119, 9);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('6WPECH', 'Skyhawk II', 'Starlight Jets', 171, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('JW2PMS', 'Falcon III', 'Skyline Aviation', 183, 5);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('BE0AVV', 'Thunderbird III', 'Wingmaster Industries', 172, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('7S8CVD', 'Wingmaster', 'Wingmaster Industries', 178, 15);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('MZFXCJ', 'Firefly', 'Thunderbird Aircraft', 158, 8);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('28GN5Q', 'Stormrider II', 'Bluebird Aircraft', 139, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('73QMVA', 'Thunderbolt', 'AeroStar Corporation', 118, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('6RR195', 'Firebird III', 'AeroStar Corporation', 166, 4);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('Z5O6KQ', 'Wingmaster II', 'AeroTech Industries', 171, 7);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('UHOB95', 'Falcon III', 'Silverwing Aerospace', 191, 16);
insert into MAYBAY (MAMB, TENMAYBAY, HANGSANXUAT, SOGHETHUONG, SOGHEVIP) values ('HZ2CCY', 'Aerowolf II', 'Skybound Aviation', 191, 9);

-- Thêm dữ liệu cho bảng CHUYENBAY
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AE 660  ', 'NCE-FRN ', 'XZPZGJ  ', '2025-05-25', '18:28:00', '22:27:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AG 553  ', 'BBW-AMA ', 'YL3LHE  ', '2025-06-19', '10:03:00', '10:24:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AN 989  ', 'MBX-WLW ', 'XRSEF9  ', '2025-05-29', '10:22:00', '19:20:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AT 362  ', 'BKD-TRG ', 'ZG6Z15  ', '2025-11-08', '21:46:00', '18:49:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('BC 789  ', 'KDP-AMA ', 'ZGM912  ', '2025-02-06', '04:42:00', '22:48:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('BL 389  ', 'MGR-NCE ', 'XRSEF9  ', '2025-03-17', '23:37:00', '00:48:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CC 450  ', 'MGR-NCE ', 'YZ2IOF  ', '2025-04-27', '22:58:00', '08:49:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CD 263  ', 'FRO-SAF ', 'Y9XRBH  ', '2025-06-09', '08:15:00', '04:35:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CJ 329  ', 'SWV-TDA ', 'Z3SU5Y  ', '2025-01-30', '16:45:00', '10:16:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CM 255  ', 'MMH-SQO ', 'YZ2IOF  ', '2025-03-07', '18:42:00', '01:32:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CR 563  ', 'KSL-SWV ', 'XI1JDN  ', '2025-11-06', '20:56:00', '09:42:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CS 257  ', 'FCM-AMA ', 'YPLXH5  ', '2025-06-05', '11:08:00', '17:18:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CU 216  ', 'SWV-TDA ', 'Y2MJ8M  ', '2025-03-01', '08:54:00', '09:54:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CU 286  ', 'AMA-TRG ', 'YZ2IOF  ', '2025-12-09', '19:14:00', '18:14:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DE 995  ', 'BOT-PPU ', 'ZS3VCX  ', '2025-11-14', '02:45:00', '16:43:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DF 740  ', 'SAF-WLW ', 'ZQI5XW  ', '2025-08-27', '09:46:00', '16:43:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DT 673  ', 'ABK-MVK ', 'YPLXH5  ', '2025-03-24', '01:25:00', '09:20:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DY 653  ', 'ERG-SQO ', 'XRSEF9  ', '2025-01-03', '14:12:00', '23:22:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EA 714  ', 'HGU-CKE ', 'XI1JDN  ', '2025-06-26', '13:02:00', '17:43:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EA 805  ', 'PTT-FDE ', 'YW8XMY  ', '2025-09-30', '00:17:00', '19:40:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EB 303  ', 'MBX-ABK ', 'YZ2IOF  ', '2025-07-02', '19:55:00', '19:09:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EE 682  ', 'CKE-SAF ', 'ZS3VCX  ', '2025-01-27', '07:37:00', '20:17:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EI 901  ', 'ARS-BBW ', 'Z3SU5Y  ', '2025-01-20', '21:30:00', '07:28:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EL 557  ', 'ORN-SAF ', 'Y2MJ8M  ', '2025-04-19', '17:52:00', '15:12:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EN 334  ', 'MGR-TUA ', 'Y3DFPY  ', '2025-08-15', '20:16:00', '12:29:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FK 002  ', 'KSL-ARS ', 'YZ2IOF  ', '2025-10-01', '19:06:00', '05:17:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FM 573  ', 'OKJ-SQO ', 'ZG6Z15  ', '2025-10-24', '02:15:00', '22:26:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FQ 490  ', 'KSL-BBW ', 'Z5O6KQ  ', '2025-01-02', '16:15:00', '16:40:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FT 190  ', 'ABK-TAB ', 'ZG6Z15  ', '2025-09-04', '15:56:00', '02:52:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FT 215  ', 'NKD-FRN ', 'Y3DFPY  ', '2025-01-22', '13:39:00', '15:43:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FT 589  ', 'CNW-ABK ', 'Y9XRBH  ', '2025-09-27', '07:26:00', '13:20:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FW 269  ', 'NKD-FRN ', 'XZPZGJ  ', '2025-02-02', '10:46:00', '22:34:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FZ 441  ', 'ABK-MVK ', 'Y3DFPY  ', '2025-08-06', '15:09:00', '22:14:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GE 692  ', 'FDE-FRQ ', 'Z5O6KQ  ', '2025-06-21', '19:40:00', '00:09:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GP 148  ', 'ABK-FCM ', 'XRSEF9  ', '2025-01-01', '14:03:00', '18:53:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GV 164  ', 'PPU-JRB ', 'ZQI5XW  ', '2025-07-19', '04:28:00', '08:26:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GW 845  ', 'SAF-TDA ', 'YW8XMY  ', '2025-03-24', '06:43:00', '19:26:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GX 201  ', 'LDS-FCM ', 'ZG6Z15  ', '2025-06-24', '06:15:00', '11:21:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GZ 512  ', 'CKE-SQZ ', 'ZG6Z15  ', '2025-02-16', '00:04:00', '21:45:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('HD 186  ', 'CKE-SQZ ', 'ZGM912  ', '2025-08-08', '20:39:00', '16:34:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('HD 430  ', 'TRG-CKE ', 'XVNM2Z  ', '2025-02-20', '23:20:00', '00:21:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IA 834  ', 'NCE-FRN ', 'ZQI5XW  ', '2025-01-03', '18:51:00', '12:26:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IF 068  ', 'NCE-FRN ', 'XI1JDN  ', '2025-09-07', '18:01:00', '01:30:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IG 452  ', 'ORN-NCE ', 'Y3DFPY  ', '2025-04-16', '20:20:00', '14:44:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IH 336  ', 'BLD-GAV ', 'ZS3VCX  ', '2025-09-26', '12:06:00', '07:39:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IJ 564  ', 'ARS-CNW ', 'XRSEF9  ', '2025-04-27', '13:22:00', '13:47:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IX 315  ', 'TRG-CKE ', 'Z3SU5Y  ', '2025-11-22', '18:26:00', '03:32:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JK 999  ', 'FDE-MBX ', 'YZ2IOF  ', '2025-12-04', '15:41:00', '06:36:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JR 712  ', 'FRO-SKQ ', 'Y2MJ8M  ', '2025-12-26', '06:19:00', '00:57:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JW 088  ', 'PTT-FDE ', 'Y2MJ8M  ', '2025-10-05', '07:36:00', '19:56:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JZ 483  ', 'BOT-ORN ', 'ZQI5XW  ', '2025-08-09', '20:28:00', '02:12:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KB 938  ', 'ERG-SQZ ', 'ZQI5XW  ', '2025-12-05', '09:22:00', '21:07:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KG 314  ', 'KDP-WLW ', 'XI1JDN  ', '2025-04-19', '00:59:00', '02:04:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KH 340  ', 'BLD-GAV ', 'YZ2IOF  ', '2025-01-20', '05:25:00', '17:51:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LU 202  ', 'FRQ-SYB ', 'ZGM912  ', '2025-12-27', '06:46:00', '23:12:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LV 508  ', 'ERG-TUA ', 'YZ2IOF  ', '2025-12-16', '18:45:00', '17:16:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LW 020  ', 'YWB-FRO ', 'YPLXH5  ', '2025-07-15', '15:46:00', '06:54:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LX 199  ', 'ARS-CNW ', 'ZGM912  ', '2025-09-16', '01:51:00', '18:42:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MG 930  ', 'TUA-OKJ ', 'Z5O6KQ  ', '2025-04-30', '02:20:00', '10:30:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ML 770  ', 'JRB-MBX ', 'ZG6Z15  ', '2025-01-25', '01:51:00', '20:59:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MP 271  ', 'HGU-CKE ', 'XRSEF9  ', '2025-02-23', '22:23:00', '08:38:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MQ 793  ', 'SYB-TDA ', 'Z3SU5Y  ', '2025-03-31', '01:54:00', '11:41:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MU 795  ', 'URC-PTT ', 'ZS3VCX  ', '2025-03-16', '08:10:00', '11:26:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NE 668  ', 'BLD-CNW ', 'Y3DFPY  ', '2025-05-26', '18:19:00', '23:23:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NR 260  ', 'HGU-CKE ', 'ZGM912  ', '2025-11-26', '22:56:00', '10:46:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NS 674  ', 'BLD-GAV ', 'Z5O6KQ  ', '2025-11-02', '22:50:00', '04:09:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NS 842  ', 'PJB-MBX ', 'Z3SU5Y  ', '2025-09-15', '21:37:00', '14:11:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OB 839  ', 'FCM-AMA ', 'ZG6Z15  ', '2025-03-26', '10:15:00', '08:29:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OC 854  ', 'YWB-FRO ', 'XZPZGJ  ', '2025-02-19', '12:25:00', '22:23:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OJ 008  ', 'NCE-FRN ', 'Y3DFPY  ', '2025-05-04', '15:43:00', '01:46:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OL 737  ', 'MBX-SUT ', 'XI1JDN  ', '2025-08-26', '02:30:00', '20:59:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PE 344  ', 'MGR-PJB ', 'Y3DFPY  ', '2025-07-01', '20:58:00', '17:20:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PI 349  ', 'MGR-TUA ', 'YPLXH5  ', '2025-11-14', '14:43:00', '20:43:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PI 359  ', 'MGR-MVK ', 'YZ2IOF  ', '2025-09-03', '14:07:00', '15:07:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PK 064  ', 'CKE-SAF ', 'XI1JDN  ', '2025-07-12', '09:52:00', '16:29:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PO 705  ', 'ORN-BKD ', 'YW8XMY  ', '2025-05-29', '20:59:00', '16:38:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QF 239  ', 'MVK-TRG ', 'XVNM2Z  ', '2025-04-13', '21:18:00', '21:36:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QF 607  ', 'MBX-SUT ', 'ZG6Z15  ', '2025-03-04', '04:01:00', '16:59:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QH 964  ', 'PTT-FRO ', 'XVNM2Z  ', '2025-09-23', '12:15:00', '08:08:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QM 350  ', 'URC-WLW ', 'YL3LHE  ', '2025-12-11', '03:39:00', '01:46:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QS 839  ', 'FDE-MBX ', 'Y2MJ8M  ', '2025-12-24', '08:45:00', '08:33:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QZ 396  ', 'MGD-SUT ', 'Z3SU5Y  ', '2025-04-03', '08:16:00', '14:31:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RA 632  ', 'TRG-KSL ', 'ZG6Z15  ', '2025-12-02', '00:46:00', '17:06:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RG 468  ', 'SWV-TDA ', 'Z5O6KQ  ', '2025-03-22', '17:03:00', '21:02:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RI 271  ', 'CKE-SWV ', 'Y3DFPY  ', '2025-03-07', '10:51:00', '04:05:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RS 632  ', 'BKD-MVK ', 'YZ2IOF  ', '2025-06-08', '09:47:00', '22:57:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RX 159  ', 'ERG-TUA ', 'XRSEF9  ', '2025-11-27', '20:00:00', '15:05:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SE 323  ', 'LDS-FCM ', 'Y2MJ8M  ', '2025-01-02', '23:25:00', '15:10:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ST 147  ', 'NLS-FRN ', 'YZ2IOF  ', '2025-03-31', '19:34:00', '05:18:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('TV 344  ', 'CKE-SQZ ', 'Y3DFPY  ', '2025-12-21', '20:37:00', '20:52:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UD 378  ', 'KSL-SWV ', 'Y2MJ8M  ', '2025-10-08', '23:07:00', '15:35:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UF 966  ', 'FDE-MBX ', 'YL3LHE  ', '2025-08-12', '09:34:00', '06:22:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UI 232  ', 'BOT-LDS ', 'ZS3VCX  ', '2025-05-15', '03:40:00', '02:28:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UL 806  ', 'MVK-TRG ', 'Z3SU5Y  ', '2025-05-30', '18:41:00', '07:34:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UX 023  ', 'TRG-CKE ', 'ZQI5XW  ', '2025-10-05', '09:33:00', '11:14:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VB 795  ', 'BLD-GAV ', 'XRSEF9  ', '2025-09-24', '00:32:00', '17:38:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VH 352  ', 'KSL-SUT ', 'Y2MJ8M  ', '2025-11-24', '18:13:00', '20:12:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VI 246  ', 'NKD-BLD ', 'Y9XRBH  ', '2025-08-27', '23:04:00', '13:49:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VJ 397  ', 'COF-BBW ', 'ZS3VCX  ', '2025-08-07', '15:39:00', '15:27:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VL 928  ', 'HGU-CKE ', 'Y3DFPY  ', '2025-09-22', '20:37:00', '02:40:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VP 100  ', 'NKD-BLD ', 'YZ2IOF  ', '2025-01-29', '10:10:00', '15:11:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VV 363  ', 'KSL-URC ', 'Z3SU5Y  ', '2025-08-16', '06:31:00', '04:11:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VV 600  ', 'GAV-ORN ', 'YPLXH5  ', '2025-11-13', '06:09:00', '10:08:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VZ 667  ', 'OKJ-SQO ', 'Z3SU5Y  ', '2025-10-07', '11:32:00', '20:56:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WB 728  ', 'ABK-TAB ', 'Z3SU5Y  ', '2025-01-22', '17:04:00', '01:59:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WE 064  ', 'BBW-SQZ ', 'Z3SU5Y  ', '2025-06-27', '20:38:00', '12:41:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WI 057  ', 'BLD-GAV ', 'YL3LHE  ', '2025-02-24', '20:26:00', '06:02:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WW 742  ', 'SAF-TDA ', 'YZ2IOF  ', '2025-03-16', '20:34:00', '12:47:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XF 119  ', 'BOT-ORN ', 'Y2MJ8M  ', '2025-10-20', '16:32:00', '09:13:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XF 402  ', 'NLS-FRN ', 'YW8XMY  ', '2025-08-08', '21:32:00', '13:55:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XK 113  ', 'FRO-SKQ ', 'Y3DFPY  ', '2025-01-05', '08:38:00', '07:56:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YF 362  ', 'KSL-SUT ', 'XVNM2Z  ', '2025-04-22', '07:20:00', '20:38:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YL 505  ', 'FCM-TAB ', 'Y2MJ8M  ', '2025-09-05', '00:44:00', '00:08:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YP 747  ', 'MMH-SQO ', 'ZS3VCX  ', '2025-09-05', '02:58:00', '19:29:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YS 207  ', 'ABK-BKD ', 'YW8XMY  ', '2025-08-02', '17:56:00', '12:53:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZE 184  ', 'URC-WLW ', 'XZPZGJ  ', '2025-08-11', '23:14:00', '09:06:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZG 279  ', 'BKD-GAV ', 'ZG6Z15  ', '2025-09-25', '17:37:00', '14:12:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZH 266  ', 'BBW-AMA ', 'Z3SU5Y  ', '2025-12-27', '14:33:00', '22:50:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZJ 357  ', 'FRN-TDA ', 'YL3LHE  ', '2025-01-25', '16:22:00', '16:45:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZL 530  ', 'FCM-SQO ', 'ZQI5XW  ', '2025-10-21', '10:25:00', '00:21:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZO 430  ', 'FRO-COF ', 'ZS3VCX  ', '2025-11-21', '16:46:00', '02:47:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZP 863  ', 'SAF-TDA ', 'XI1JDN  ', '2025-11-04', '03:38:00', '21:08:00');

-- Thêm dữ liệu cho bảng HANGVE
insert into HANGVE (MAHV, TENHANGVE) values ('F', 'First class');
insert into HANGVE (MAHV, TENHANGVE) values ('J', 'Business');
insert into HANGVE (MAHV, TENHANGVE) values ('W', 'Premium Economy');
insert into HANGVE (MAHV, TENHANGVE) values ('Y', 'Economy');

-- Thêm dữ liệu cho bảng VAITRO
insert into VAITRO (MAVT, TENVAITRO) values ('NV', 'Employee');
insert into VAITRO (MAVT, TENVAITRO) values ('KH', 'Customer');

-- Thêm dữ liệu cho bảng NHANVIEN
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV010574', 'Raf Westoll', '16 Anthes Avenue', '0641489143', '1947-10-13', '1964-07-28', 'F', 'rwestoll8y@vkontakte.ru', 'uZ5\9{S9}h!', '1975-07-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV012052', 'Ondrea Pigne', '16 Porter Plaza', '0511790839', '1971-03-05', '1986-05-15', 'F', 'opignec3@timesonline.co.uk', 'wS6{zP#_/nZy&', '1999-12-24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV019077', 'Ford Dewey', '3 Straubel Park', '0616334311', '1994-12-12', '1996-08-25', 'M  ', 'fdewey7a@printfriendly.com', 'lD9,0_S3', '2012-10-28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV024982', 'Janith Fitzsimon', '581 Sutteridge Parkway', '0858584963', '1953-02-02', '1979-06-27', 'F  ', 'jfitzsimon51@wikimedia.org', 'rG1$9}z&', '1984-05-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV025466', 'Davine Wrought', '73683 Marcy Lane', '0408757002', '1962-09-01', '1997-08-22', 'M  ', 'dwroughts@scientificamerican.com', 'pB8,X0eWU3Yr|/', '2009-01-18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV041942', 'Nate Tindle', '8259 Logan Lane', '0339766279', '1960-02-13', '1990-07-15', 'F  ', 'ntindle3l@samsung.com', 'jT2>D|9_m+"rmh}', '1994-08-22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV042409', 'Elicia Peart', '7 Elka Terrace', '0491782729', '1975-11-03', '1999-06-23', 'F  ', 'epeart4t@hugedomains.com', 'bK1)Zy<iNkP95R9W', '2000-07-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV044506', 'Brannon Vollam', '51 Morning Way', '0746562204', '1967-02-24', '1972-01-07', 'M  ', 'bvollam70@mediafire.com', 'tY4=`/ctTojV', '1989-01-06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV047107', 'Erhard Gibbings', '22409 Homewood Way', '0112860662', '1985-11-16', '1987-01-22', 'F  ', 'egibbings8k@bloomberg.com', 'kR7@)9P(MM*}Y6d', '2008-06-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV057942', 'Cissy Ughetti', '2 Golf Course Drive', '0952993939', '1950-02-15', '1991-10-06', 'F  ', 'cughettidu@imageshack.us', 'nD5`6z6Pm=', '2020-12-07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV059671', 'Kim Heilds', '3 Northridge Parkway', '0212382811', '1968-07-28', '1974-07-06', 'M  ', 'kheilds5g@shareasale.com', 'wZ7`XZ8Y,iVie', '2022-03-22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV060507', 'Marcos Fetherstonhaugh', '86 Scofield Circle', '0101827144', '1946-03-19', '1986-03-26', 'M  ', 'mfetherstonhaugh3y@google.cn', 'vW5){X9D>@', '2015-10-31', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV068235', 'Mia Kettleson', '3030 Prentice Road', '0440563515', '1979-04-21', '1992-03-02', 'F  ', 'mkettleson75@exblog.jp', 'qU2?FN0L6WA', '2015-07-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV073871', 'Calida Blainey', '2 Bellgrove Parkway', '0802409627', '1966-12-11', '1992-05-20', 'M  ', 'cblaineybq@phpbb.com', 'qX0%aE1,7MB', '2000-12-25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV077006', 'Vaughn Massinger', '5 4th Hill', '0845361410', '1950-12-13', '1975-04-06', 'M  ', 'vmassinger5v@cdbaby.com', 'eY2?FY,`', '1980-12-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV078538', 'Sharia Gibbings', '602 Granby Way', '0358544739', '2002-01-05', '2013-08-21', 'F  ', 'sgibbings23@taobao.com', 'wD3(LOaf', '2019-01-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV078937', 'Scottie McGifford', '468 Muir Point', '0621268092', '1953-11-21', '1966-03-06', 'F  ', 'smcgifford78@livejournal.com', 'rY2+j|1', '2004-01-08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV079311', 'Stefania Mintrim', '4 Sommers Place', '0487265449', '1982-12-18', '2015-07-03', 'M  ', 'smintrimce@feedburner.com', 'eH1?la7\D#KK', '2023-05-01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV082912', 'Gustavo Battelle', '38508 Saint Paul Plaza', '0790177407', '1969-12-07', '1990-04-30', 'F  ', 'gbattelle8w@shareasale.com', 'sG6$6AS@', '2022-05-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV085281', 'Ailsun Beaven', '27036 Hoffman Plaza', '0732596324', '2003-06-19', '2014-01-10', 'F  ', 'abeaven1l@acquirethisname.com', 'kA8}+z~JSULswY&o', '2018-12-25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV092108', 'Noni Spilisy', '76882 Lindbergh Trail', '0794517380', '1959-05-26', '1998-06-09', 'F  ', 'nspilisy8l@bbc.co.uk', 'oD4,>ZtG1={i', '2012-05-12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV098182', 'Lidia Wakerley', '017 Heath Way', '0453885840', '1958-11-20', '1972-06-15', 'M  ', 'lwakerley5c@issuu.com', 'dX7|yO7c', '2005-02-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV105604', 'Laughton Endon', '76 Sutteridge Street', '0321040937', '1945-09-15', '1970-09-15', 'M  ', 'lendondq@bloomberg.com', 'vW3*q3h*', '2010-02-07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV122335', 'Liuka Letterese', '20418 Tomscot Plaza', '0381508700', '1970-04-20', '1977-02-01', 'M  ', 'lletteresebw@reference.com', 'bK6?&je"ozM', '2011-04-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV132568', 'Cornie Kerman', '333 Reindahl Terrace', '0919694626', '1968-06-28', '1999-12-11', 'M  ', 'ckerman3n@ucla.edu', 'gX0.BYC~4u{P1Z{', '2010-10-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV138088', 'Ernesto Brandin', '4 Butternut Street', '0166426735', '1958-04-18', '1997-08-27', 'M  ', 'ebrandinbk@google.pl', 'dC8#@OepU~S', '2016-03-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV158614', 'Deerdre Spitaro', '6 Hazelcrest Lane', '0103922383', '1958-06-29', '1984-04-15', 'F  ', 'dspitaro7k@dion.ne.jp', 'oF8(s*W`', '2006-10-02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV160815', 'Saxon Christopher', '3970 Clyde Gallagher Way', '0746869892', '1964-05-18', '1978-01-05', 'M  ', 'schristopher8b@boston.com', 'yY3">@LQrbM+_m*Y', '2022-12-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV161099', 'Thacher Daley', '2 Gale Circle', '0828762636', '1957-03-09', '1990-07-21', 'F  ', 'tdaley5p@ftc.gov', 'gZ9(@H%}(', '1995-05-29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV164312', 'Nollie Jirka', '4665 Carey Junction', '0432345500', '1951-11-21', '1973-09-16', 'M  ', 'njirkad7@newyorker.com', 'gZ9"h|QbJs', '1997-05-21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV178173', 'Madison Linning', '813 Hoard Road', '0164673266', '1947-10-09', '1976-11-11', 'F  ', 'mlinningbb@ucoz.com', 'lY2?vyu9', '2021-01-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV180911', 'Kerk Brahm', '41789 Lake View Parkway', '0330228577', '1945-06-14', '1975-02-26', 'M  ', 'kbrahmbd@posterous.com', 'hN5<i2t.xRR4P', '2005-04-02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV189822', 'Karrie Creighton', '1 Vermont Street', '0498348911', '1969-02-13', '1999-01-11', 'M  ', 'kcreighton8q@theatlantic.com', 'yM9"Vj!4', '2006-08-22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV193026', 'Frants Brushfield', '09 North Place', '0324121152', '1975-11-01', '1987-08-14', 'M  ', 'fbrushfieldc1@google.com.hk', 'eD5|{*qB', '1993-12-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV193469', 'Ferdinanda Portingale', '209 Superior Terrace', '0894770878', '1974-04-30', '1975-09-13', 'F  ', 'fportingale5h@google.com.au', 'mS6@*Ha\/', '2011-10-18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV196736', 'Stan Spurret', '4 Village Green Junction', '0675615877', '1951-04-22', '2004-12-10', 'F  ', 'sspurret7h@goo.ne.jp', 'rZ1<1=t.jtCbe', '2017-06-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV201665', 'Donal Janaway', '4 Vermont Road', '0492401216', '1959-06-08', '2008-04-01', 'F  ', 'djanaway6g@forbes.com', 'oZ0,8jo)', '2016-04-10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV223401', 'Sherlocke Rallinshaw', '20201 Hanover Point', '0963913902', '1951-09-02', '1964-02-20', 'M  ', 'srallinshaw1r@samsung.com', 'aE0(Ng<F!0Z40jQ', '1970-12-28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV234271', 'Bone Crace', '05 Marquette Pass', '0920822440', '1979-08-24', '1983-10-22', 'F  ', 'bcraced5@istockphoto.com', 'kD3%shkY@', '2020-03-02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV240888', 'Skell Hotchkin', '7336 Washington Street', '0909022702', '1959-02-24', '1974-11-01', 'M  ', 'shotchkin2x@pagesperso-orange.fr', 'uV7.8!2OT{q>Y~', '2017-10-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV240973', 'Gisela Cumberledge', '3 Annamark Park', '0839156879', '1975-03-21', '1989-07-03', 'F  ', 'gcumberledge4e@army.mil', 'xH6?suQh4GR>VvMS', '2016-02-11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV242498', 'Lyndsey Roux', '4242 Oriole Parkway', '0520147788', '1975-10-21', '1979-08-11', 'F  ', 'lroux6s@alexa.com', 'sT0*ly=R*g~#h{?)', '2014-03-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV253335', 'Ruben Raymen', '34095 Clyde Gallagher Alley', '0832413147', '1951-11-02', '1984-05-25', 'F  ', 'rraymen3q@yahoo.co.jp', 'zM4<RC~4E}U', '1987-03-23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV259903', 'Allie Hairsnape', '31 West Court', '0127752547', '1980-04-15', '1980-08-29', 'M  ', 'ahairsnape4n@mail.ru', 'bG3|Ze3+/V', '1999-01-28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV262355', 'Cindelyn Pile', '56574 Center Court', '0996529870', '1968-06-02', '1972-06-18', 'F  ', 'cpileck@house.gov', 'vP9!KSw(H3', '2013-12-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV264057', 'Haily Biddlestone', '7 Morrow Way', '0289464052', '1983-09-01', '2005-02-03', 'F  ', 'hbiddlestone15@walmart.com', 'xA7*&6m/Mg', '2016-01-21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV271794', 'Shirlene Meads', '3 Katie Crossing', '0160165707', '1977-09-09', '1988-08-10', 'M  ', 'smeads7w@msn.com', 'aQ5(exe6q', '2002-04-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV277291', 'Melicent Janic', '5 American Terrace', '0833843519', '1954-03-24', '1965-09-20', 'M  ', 'mjanic66@gravatar.com', 'xU0,dGJ3)1>#KuC', '1977-08-16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV281921', 'Carling Charlet', '3128 Sachs Place', '0180957537', '1953-12-07', '1980-04-26', 'F  ', 'ccharlet8c@w3.org', 'kR4(qUB0Ukl', '2002-08-02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV288830', 'Tedda Tomney', '31 Arkansas Junction', '0220914982', '1972-09-20', '2009-06-04', 'F  ', 'ttomney47@springer.com', 'rU6\5qB3XxKZ7', '2015-05-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV289904', 'Lorin Smorthwaite', '0 Nova Terrace', '0897880447', '1979-08-16', '1985-07-18', 'F  ', 'lsmorthwaite9u@ucsd.edu', 'qI8>KIN(d0u?!F', '2015-11-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV297438', 'Mercie Poppleston', '6234 Dryden Place', '0923163354', '1947-04-16', '1971-09-24', 'M  ', 'mpopplestonb3@techcrunch.com', 'jZ3_nFOYVK*JL8r#', '1972-04-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV303199', 'Karney Ogborn', '86 Kipling Center', '0362886993', '1977-08-29', '1994-06-26', 'F  ', 'kogborndp@jigsy.com', 'cS9,\4sn5)N_I', '2001-02-03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV303894', 'Christian Faulconer', '10 Doe Crossing Road', '0966976836', '1950-08-31', '2002-01-17', 'F  ', 'cfaulconer7e@sfgate.com', 'fN8&i?OH$\@H', '2004-07-12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV303957', 'Jemima O Quirk', '273 Express Drive', '0606590703', '1947-10-21', '2004-11-27', 'M  ', 'jodk@google.ru', 'nW6=jjTMeWi2(*', '2017-01-01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV308774', 'Derron Fiander', '345 Center Crossing', '0532123764', '1959-01-20', '1979-07-14', 'M  ', 'dfiander6e@huffingtonpost.com', 'pZ4/g~aV', '1979-09-19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV325416', 'Jaclin Mehaffey', '42890 Browning Drive', '0119837575', '1963-12-01', '1977-05-21', 'F  ', 'jmehaffey84@technorati.com', 'mK8/|#DJgrQ4(', '1977-11-12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV327641', 'Harold Telega', '478 Badeau Plaza', '0256841895', '1953-05-15', '1972-10-18', 'M  ', 'htelega3u@edublogs.org', 'uS2#Jxu$', '2016-07-12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV336685', 'Roch Manuello', '69666 Debra Parkway', '0833372027', '1952-01-31', '1976-06-02', 'F  ', 'rmanuello2b@hao123.com', 'iD5|&"*u,j', '2006-05-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV339957', 'Jeth Purton', '013 International Pass', '0755142627', '1995-11-08', '2006-02-24', 'F  ', 'jpurtoncv@aboutads.info', 'yI5.|j&L)p)Y', '2021-07-08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV340941', 'Kelsi Russell', '240 Goodland Court', '0454062370', '1972-11-29', '1983-06-27', 'F  ', 'krussellb6@examiner.com', 'vH2`S/ZQ61wVO', '1988-03-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV343692', 'Kin Brosius', '02 Waxwing Crossing', '0617541461', '1961-10-30', '1964-10-11', 'M  ', 'kbrosius76@engadget.com', 'sB7#axesb*', '2013-08-16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV363798', 'Olvan Woodham', '69689 Schlimgen Center', '0783242715', '1974-04-13', '2002-04-03', 'M  ', 'owoodhamcj@4shared.com', 'rT9~NO.<(FK', '2021-07-24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV367893', 'Lucy Huzzey', '36738 Westend Road', '0701327864', '1958-07-21', '1964-06-05', 'M  ', 'lhuzzeybe@technorati.com', 'sQ9?#zxmuB', '1976-05-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV372709', 'Rianon Noulton', '420 Huxley Parkway', '0758922662', '1972-11-05', '1978-02-12', 'M  ', 'rnoulton7g@e-recht24.de', 'rK6`Bct>D0Q7gx', '1999-01-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV376524', 'Nancie Melvin', '98 Sherman Place', '0480477992', '1980-09-26', '2002-06-06', 'F  ', 'nmelvinbs@virginia.edu', 'wT3~gPzq_b/&?', '2004-07-03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV383849', 'Dino Porcas', '47960 Butterfield Pass', '024561074', '1951-05-29', '1999-04-20', 'M  ', 'dporcas7t@go.com', 'uY9%fC<in', '2016-01-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV391581', 'Woodrow Baumaier', '87231 3rd Lane', '0849016900', '1972-06-11', '1977-11-14', 'F  ', 'wbaumaier2y@pcworld.com', 'aX1.KKfl$x', '1990-04-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV392010', 'Rurik Priel', '28320 Talisman Way', '0878840118', '1985-03-24', '1997-03-17', 'F  ', 'rprielav@typepad.com', 'nX4)aQ0f4j_b`0', '2019-03-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV392461', 'Niels Haskins', '5651 Sommers Park', '068381576', '1966-08-14', '1970-10-31', 'M  ', 'nhaskinsc2@furl.net', 'rU7/Yr6vZ4kW', '2022-08-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV408057', 'Hymie Bostock', '01407 Lake View Terrace', '0108529206', '1974-11-21', '1977-09-04', 'F  ', 'hbostock85@hud.gov', 'uN5*lPEG"JY3}EsE', '1989-12-25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV413814', 'Franklyn Passman', '3455 Dottie Parkway', '038331397', '1971-03-01', '2001-06-15', 'F  ', 'fpassmanbz@ed.gov', 'hW6@gEP/T4Oxfq', '2019-12-24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV415824', 'Melitta Callingham', '760 Holmberg Street', '0196348348', '1982-02-06', '1997-04-13', 'M  ', 'mcallinghamdo@craigslist.org', 'vX9}X1*W~yq', '2018-11-25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV425018', 'Amabelle Sibbit', '12 Heath Center', '0219500504', '2001-12-20', '2004-07-24', 'M  ', 'asibbit4@etsy.com', 'pJ1"$y\wsV,', '2010-03-16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV429712', 'Weider Brizland', '553 Almo Park', '0497202651', '1949-12-21', '1994-08-17', 'M  ', 'wbrizland7u@washingtonpost.com', 'mM7(MGz9B8L6BE', '2015-10-23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV430597', 'Linn Fishburn', '1347 Banding Street', '028171878', '1948-05-01', '1996-12-10', 'M  ', 'lfishburnp@nps.gov', 'dU3(cX6a$L"BqUTp', '2004-02-11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV433504', 'Diana Blanket', '380 Carpenter Drive', '0604869147', '1951-10-22', '2003-03-10', 'M  ', 'dblanketdi@yelp.com', 'dA8+sTsw', '2005-08-29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV439113', 'Danny McAlister', '7514 Northridge Way', '0791085836', '1948-03-11', '1966-07-18', 'F  ', 'dmcalister2g@ucsd.edu', 'tH3#P8Cy&b9', '1978-06-01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV440528', 'Danyelle Pettit', '87522 Fisk Place', '0228623581', '1965-08-28', '1980-06-29', 'M  ', 'dpettitdr@miibeian.gov.cn', 'eG5/G0ZuT>H!', '2015-04-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV441589', 'Concettina Tchir', '2 Vernon Trail', '0860300395', '1966-03-23', '1969-01-08', 'M  ', 'ctchirm@liveinternet.ru', 'yJ0<(|RYA,!0', '1978-12-08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV444738', 'Joya Sinnott', '08 Melrose Parkway', '0287613206', '1945-03-18', '1969-07-23', 'F  ', 'jsinnott5@answers.com', 'mT5(|}WNWb)i<M/', '1994-07-18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV447108', 'Salli Levee', '584 Maple Wood Crossing', '013593182', '1980-07-12', '2015-08-11', 'M  ', 'slevee62@psu.edu', 'dP8/ac`.Q8UO7', '2020-11-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV450177', 'Pattie Turfin', '2 Sutherland Crossing', '0939593568', '1965-12-16', '1975-06-28', 'M  ', 'pturfin6w@tmall.com', 'oM6|(I?%hK9}|!', '1988-06-19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV453523', 'Ingamar Aberkirder', '67631 Crest Line Place', '0305220605', '1966-05-27', '1996-07-19', 'F  ', 'iaberkirderb9@scientificamerican.com', 'sA6<+M|U`n', '2015-01-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV454412', 'Umeko Beauchamp', '4 Mayer Circle', '0985503101', '1959-07-28', '2002-11-16', 'F  ', 'ubeauchamp63@scientificamerican.com', 'bD1Tzh?,', '2015-05-18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV477238', 'Sancho Pevreal', '96746 Golf Avenue', '074110425', '1950-09-02', '1998-08-24', 'M  ', 'spevreal5u@stanford.edu', 'zY3%n6c3i.mkt', '2022-07-02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV480270', 'Darelle Cawt', '2 Veith Court', '0778158195', '1965-06-25', '1982-03-01', 'F  ', 'dcawt30@omniture.com', 'zQ1{_3?9eo', '1994-06-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV481500', 'Gerta Povlsen', '8685 Logan Drive', '0646035780', '1953-08-08', '1969-10-15', 'F  ', 'gpovlsen7d@fc2.com', 'bE7/vuj(lew', '1991-06-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV487204', 'Forrester Lorman', '8 Lighthouse Bay Point', '0870567961', '1957-05-04', '1979-05-24', 'F  ', 'florman49@chicagotribune.com', 'qO2_P>&5YGKie', '2006-01-27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV496066', 'Vergil Fraulo', '7 East Place', '0504605990', '1970-06-18', '1979-07-06', 'M  ', 'vfraulo7o@live.com', 'mB7)"yn,6hZeyB', '2017-11-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV510405', 'Nita Thackwray', '3110 Holmberg Center', '019095935', '1984-10-27', '1988-10-06', 'M  ', 'nthackwray3b@google.ca', 'hI3.lm1zIHa', '2004-01-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV518097', 'Frazer Wrathall', '3 Mariners Cove Park', '059641579', '1967-06-07', '1997-08-20', 'F  ', 'fwrathallr@netlog.com', 'eB5%%ps.m\rz8(6', '2007-06-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV521642', 'Morganne Sabin', '8 Schlimgen Crossing', '0310204431', '1960-12-11', '1982-02-06', 'F  ', 'msabin4w@ehow.com', 'iA5/T@%_IX', '2007-12-28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV524840', 'Tiffie Radolf', '58086 Moulton Circle', '0559868979', '1950-06-09', '2006-12-12', 'M  ', 'tradolf17@china.com.cn', 'qO8_qj&66', '2008-09-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV531991', 'Anthony Anderbrugge', '0442 Spaight Parkway', '0244935684', '1969-09-06', '1987-07-17', 'M  ', 'aanderbrugge1s@unesco.org', 'aW4"xQVU', '1994-10-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV539311', 'Matthew Smalley', '4 Dapin Avenue', '0158051749', '1973-04-02', '1978-08-07', 'M  ', 'msmalley4b@nih.gov', 'oV2@P.H1bJ4*$2a', '1986-10-27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV540497', 'Bevin Seiller', '30609 Sugar Alley', '0528787221', '1953-12-20', '2004-06-05', 'F  ', 'bseiller4d@dot.gov', 'dJ5!8/6FvDbG`', '2004-12-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV550817', 'Danila Sprionghall', '26470 Melby Hill', '0261142847', '1963-01-10', '1987-05-27', 'F  ', 'dsprionghall14@stumbleupon.com', 'lK8$8P#VEv', '2022-09-01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV568902', 'Sylvia Spain-Gower', '9469 Gina Trail', '062394314', '1950-06-04', '1985-05-30', 'F  ', 'sspaingower6x@360.cn', 'yJ2/tFh&RXIdw', '1999-11-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV573727', 'Marcelline Barth', '91 Iowa Road', '0650645851', '1959-03-23', '1963-04-15', 'F  ', 'mbarthao@elegantthemes.com', 'mE4/DilmC.Q', '2014-01-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV574049', 'Fraser Fountain', '38 Vidon Place', '0477195533', '1947-06-14', '1995-03-07', 'M  ', 'ffountainan@xrea.com', 'eH8&~zEUj', '2017-01-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV579268', 'Fionnula Pack', '66599 Oak Crossing', '030291619', '1963-03-06', '1978-11-26', 'F  ', 'fpack83@bravesites.com', 'jG6}PUD_+O', '2003-06-21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV582109', 'Ola de Tocqueville', '58223 Elka Point', '0449860223', '1972-11-29', '1975-02-04', 'M  ', 'odedv@blogger.com', 'iK9_qR_!=YN', '1989-06-04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV592137', 'Fonsie McElmurray', '42 Bellgrove Trail', '0331117995', '1958-07-05', '1965-01-24', 'M  ', 'fmcelmurray94@360.cn', 'wC8><mAR', '1972-02-21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV594273', 'Brigid Kolakowski', '7 Dorton Circle', '0953902659', '1950-03-25', '1983-02-21', 'F  ', 'bkolakowskid9@liveinternet.ru', 'jD9%|n7WcB\qc', '2010-07-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV596246', 'Roman Haburne', '81780 Rutledge Parkway', '0973085296', '1957-12-01', '1979-08-02', 'F  ', 'rhaburne6v@vistaprint.com', 'yM7}1|H=', '2004-09-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV610092', 'Nina Epine', '94996 Rutledge Crossing', '0950340745', '1950-07-12', '1997-05-20', 'F  ', 'nepinedg@wp.com', 'qP6&&>6n2)FQ/j', '2002-01-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV619036', 'Josh Carnilian', '082 Glacier Hill Alley', '095312046', '1999-05-18', '2004-04-22', 'M  ', 'jcarniliand0@webeden.co.uk', 'gC4?R2Z8`g%jl"', '2008-11-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV619570', 'Olenka Attyeo', '794 Hazelcrest Alley', '0904569240', '1953-05-24', '1981-02-16', 'F  ', 'oattyeo36@gizmodo.com', 'oH3&2sf$', '1999-03-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV620763', 'Eleanora Aubery', '877 Raven Crossing', '0789557631', '1950-12-28', '1970-12-05', 'M  ', 'eauberybv@addtoany.com', 'bQ8?TNFs|H"nzt', '2005-11-24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV634749', 'Violetta OIlier', '63 Summer Ridge Point', '0111927536', '1965-03-20', '1997-07-26', 'F  ', 'voilier10@imdb.com', 'iP5@6SFv', '2022-11-08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV639320', 'Sondra Blaise', '057 Muir Drive', '0537380184', '1975-08-12', '2000-05-14', 'F  ', 'sblaisec5@geocities.com', 'yG0)aYWs6@ZX8N&=', '2011-05-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV645678', 'Quincy Barneville', '122 Twin Pines Road', '0832708962', '1948-01-13', '2002-04-11', 'F  ', 'qbarnevillecu@oakley.com', 'cK5!%n62{', '2007-12-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV650538', 'Mellisent Juliano', '241 Carberry Alley', '0545573874', '1948-06-01', '1971-06-03', 'M  ', 'mjuliano95@fda.gov', 'hA4"s!X"?X}r"~', '1990-03-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV659671', 'Gwenette Moxstead', '52678 Johnson Way', '0336102247', '1959-01-25', '1974-02-17', 'M  ', 'gmoxstead39@psu.edu', 'gD7/mAg$_jBks', '2020-07-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV659802', 'Davina Edmondson', '33117 Bashford Parkway', '0351938606', '1966-01-08', '2010-12-21', 'F  ', 'dedmondson2d@e-recht24.de', 'hU2+3DnVWg', '2017-07-03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV660217', 'Ibbie Pietroni', '84315 Gateway Way', '0657038222', '1966-09-17', '1975-01-15', 'M  ', 'ipietronic7@wired.com', 'uD6)/m~`4', '1977-12-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV660753', 'Gray Ventris', '9515 Havey Park', '038648797', '1945-06-20', '1964-01-28', 'M  ', 'gventrisd6@networksolutions.com', 'bO5+yGbv', '2001-03-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV675961', 'Jackie Eldritt', '1 Fuller Parkway', '0732384992', '1968-03-09', '1989-02-01', 'M  ', 'jeldrittq@amazonaws.com', 'cN5%t1GH*M(,t', '2021-09-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV676162', 'Graeme Izaac', '6 Hanson Center', '0765952239', '1948-10-05', '1972-10-16', 'F  ', 'gizaac3m@indiegogo.com', 'zC3)%9#GwnWZ/_7@', '1993-02-18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV711456', 'Adoree Blaschek', '4554 Blackbird Trail', '0834800671', '1973-07-07', '1986-01-11', 'M  ', 'ablaschek1u@mysql.com', 'mD6|zu|u', '2005-10-13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV717819', 'Jackelyn Mottershaw', '86 Elgar Avenue', '0966845207', '1996-03-01', '1997-09-05', 'M  ', 'jmottershaw7n@dailymail.co.uk', 'hO8\rHLWRgctM', '2016-09-22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV732368', 'Adel Perrins', '8663 Pearson Hill', '0287216536', '1963-07-27', '1965-07-22', 'M  ', 'aperrins91@fda.gov', 'qJ4\=+=SO.}51', '1992-12-12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV735464', 'Chase Charette', '2280 Thackeray Way', '0437313759', '1964-09-01', '2006-03-22', 'F  ', 'ccharette2w@omniture.com', 'lW2)A3GCX', '2022-05-24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV738399', 'Eldridge Ambroisin', '8507 Packers Street', '0179270375', '1951-08-15', '1982-06-27', 'F  ', 'eambroisin6u@bbc.co.uk', 'aK6?DAm,whK!', '1995-01-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV740277', 'Cody Mordaunt', '01760 Novick Pass', '0326585276', '1951-11-12', '1974-12-08', 'M  ', 'cmordaunt9d@google.com.br', 'dM6#n0$0b3O_##', '1984-07-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV747397', 'Binni Spada', '1470 Southridge Center', '0456089600', '1951-12-13', '1966-04-15', 'F  ', 'bspadav@51.la', 'oZ7%WZ6i{G', '2022-08-03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV770980', 'Kaile Densumbe', '4 Waywood Way', '0607808539', '1959-01-23', '1963-10-09', 'F  ', 'kdensumbe2@scientificamerican.com', 'rA3%l@}}88b&V', '2020-11-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV775515', 'Daria Benettini', '2 Annamark Terrace', '0630424812', '1962-07-03', '1986-11-05', 'F  ', 'dbenettini4x@imgur.com', 'hX3}svvn', '1996-11-23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV787213', 'Minne Walsom', '06799 John Wall Plaza', '0987188925', '1959-10-06', '1980-01-28', 'M  ', 'mwalsom1m@java.com', 'sQ0(Qupk+PO', '1981-05-31', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV789781', 'Analiese Wimpress', '0 Namekagon Center', '0145600059', '1975-12-03', '1987-08-03', 'F  ', 'awimpressbl@usda.gov', 'mF0>0eA&BE#', '2021-06-27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV790581', 'Martita Denyukhin', '7 John Wall Point', '0964456517', '1977-08-26', '1991-10-23', 'M  ', 'mdenyukhin29@bluehost.com', 'jK8>LM>&rph', '2021-12-09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV797940', 'Noble Joll', '9221 Maple Wood Avenue', '0784302929', '1947-04-22', '1965-08-27', 'F  ', 'njollk@cloudflare.com', 'gU5<0)@<pFQ3qxqM', '2005-09-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV822716', 'Tatiana Wand', '7 Hallows Street', '0800133979', '1945-12-19', '1979-12-03', 'F  ', 'twandcd@tiny.cc', 'bH0>C48AmvFa0', '1985-08-17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV832790', 'Prent Sellors', '5 Sutteridge Crossing', '0469800545', '1948-03-15', '1978-12-11', 'F  ', 'psellorsdm@java.com', 'uP0@Rn9uqaq', '1981-04-30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV835274', 'Lane Lewzey', '13 Lakewood Gardens Pass', '0782691279', '1985-02-12', '1997-03-05', 'M  ', 'llewzey6r@umn.edu', 'cT3\RCN<#lW', '2004-01-03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV849197', 'Sada Cresar', '3 Hoepker Junction', '0892258745', '1983-07-15', '2020-01-02', 'M  ', 'scresar7z@uol.com.br', 'oJ2)$2%{F0lE', '2021-04-16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV849707', 'Konrad Lakin', '27 Barby Circle', '0316544335', '1962-09-29', '1969-08-10', 'F  ', 'klakin55@ed.gov', 'xK1/CCKgA|tU', '1973-04-28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV850038', 'Elsinore Ambrosoni', '3 Maywood Pass', '0959362074', '1961-03-04', '1983-05-09', 'M  ', 'eambrosoni6h@ifeng.com', 'lJ9#N+AjCiqR', '2018-04-08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV850462', 'Rebecka Brigdale', '56240 Springs Junction', '0176335672', '1977-06-21', '2008-09-08', 'M  ', 'rbrigdale2r@berkeley.edu', 'nF7.Tkk6rz{1{9~', '2015-10-06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV856226', 'Blayne McKeran', '35 Magdeline Alley', '0542040238', '1990-12-14', '1994-04-11', 'M  ', 'bmckeran5m@youtube.com', 'fU1*CF"L', '1998-05-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV875495', 'Eveleen Cayser', '21337 Morningstar Point', '0998756303', '1973-08-12', '1996-09-08', 'F  ', 'ecayser3t@china.com.cn', 'mQ5|@)j?ZR', '2024-01-19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV888660', 'Carla MacNair', '31972 Talmadge Road', '0334663970', '1949-03-17', '1975-08-05', 'F  ', 'cmacnair5d@bravesites.com', 'lT0}2j6w%`Z`', '1983-09-11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV890100', 'Guinna Shimon', '4 Onsgard Avenue', '0485295523', '1955-02-02', '2021-02-11', 'M  ', 'gshimoncg@creativecommons.org', 'hT2+id15NTB=46', '2022-11-18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV890913', 'Hersh Opdenorth', '57226 Washington Park', '0885455246', '1967-02-16', '1974-09-06', 'F  ', 'hopdenorth2f@yale.edu', 'wY2*\%hvOe', '2015-02-19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV894914', 'Anetta Dering', '62 Beilfuss Center', '0835734952', '1972-08-17', '1973-05-24', 'M  ', 'adering89@netlog.com', 'tJ7(@b%E,~)oWk', '1978-03-05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV901134', 'Waldo Benedit', '99 Eliot Trail', '0399871432', '1977-10-20', '2004-07-17', 'F  ', 'wbenedit28@weibo.com', 'yJ2+n>ooKta6W+T3', '2010-08-29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV905823', 'Norbie Ciric', '5 Warner Circle', '0185620939', '1946-12-19', '1971-12-20', 'F  ', 'nciric9a@amazon.co.uk', 'zS9_gi(VVb|+3', '2015-09-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV921688', 'Dianne Loving', '4796 Memorial Park', '0886454292', '1949-06-26', '2000-08-25', 'M  ', 'dlovingdl@patch.com', 'hQ9}qI"S08', '2004-12-15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV925832', 'Silvester Bambrick', '0 Mifflin Hill', '0663817395', '1948-05-24', '1990-05-28', 'F  ', 'sbambrick37@imdb.com', 'jD0?9OJ)H#fClT', '2010-11-29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV928013', 'Bee Fouldes', '35711 Prairieview Hill', '0362049387', '1975-07-09', '1999-08-09', 'F  ', 'bfouldesbp@reverbnation.com', 'jF2~!zom~fq"%zu', '2002-11-26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV940794', 'Verna Peidro', '52398 Wayridge Parkway', '0533103173', '1971-09-16', '1990-03-16', 'M  ', 'vpeidro11@latimes.com', 'kC5*X(w}cn2FR', '2009-01-07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV941014', 'Minny Deyes', '2 Fallview Park', '090986365', '1981-04-21', '1993-01-22', 'M  ', 'mdeyes79@jigsy.com', 'oQ1!v8Pme$@i)YT', '2016-07-11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV941879', 'Cilka Espinho', '4 Mcbride Circle', '0673723766', '1948-09-07', '1993-11-10', 'M  ', 'cespinho1y@scribd.com', 'nU0<3+TRE1qi)Vo~', '2006-05-20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV945233', 'Blair Mar', '73 Waxwing Circle', '0143384540', '1949-10-30', '1973-08-11', 'F  ', 'bmar3o@ycombinator.com', 'rX9+W_M)Z}#>_k}n', '2011-08-25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV946657', 'Maia Haskett', '8225 Warrior Alley', '0483972258', '1954-11-26', '2006-07-30', 'F  ', 'mhaskett80@amazon.co.jp', 'tS5tbe"I#Yz|ag', '2010-02-07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV946685', 'Ray Duxfield', '209 Drewry Street', '0533534627', '1947-02-15', '2000-07-16', 'M  ', 'rduxfield1i@facebook.com', 'oW7"FMnfBcOPR', '2004-06-19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV950327', 'Sunshine Barkway', '4 Fairfield Pass', '0617834052', '1966-11-08', '1999-11-13', 'F  ', 'sbarkway42@slashdot.org', 'iC0&L#J~*s$0z9', '2008-08-06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV950802', 'Beatriz Roskam', '4 Loftsgordon Plaza', '0755537665', '1986-11-12', '1988-01-06', 'F  ', 'broskamba@apple.com', 'nI1#U"mt', '2012-08-10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955706', 'Hubie Rayner', '45 Eastlawn Parkway', '0454294540', '1974-01-23', '2012-08-02', 'M  ', 'hraynerd3@ameblo.jp', 'nX8?s.6{RY', '2017-03-11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955885', 'La verne Roderick', '9819 Forest Run Hill', '0382801971', '1950-01-14', '2018-09-06', 'M  ', 'lvernebr@skype.com', 'mN3=7v{`Ght<CV', '2019-03-11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955988', 'Baron Corns', '334 Carey Hill', '0733519659', '1955-07-10', '1967-10-19', 'M  ', 'bcorns43@pcworld.com', 'gQ2/%f2tDq>T@xEy', '1983-11-22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV964113', 'Valera Luck', '17 Corry Park', '0793268002', '1947-05-10', '2003-05-04', 'F  ', 'vluckdh@icq.com', 'fK7=,iCZF', '2012-10-14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV979641', 'Manon Layfield', '30 Bobwhite Hill', '0490165757', '1967-06-21', '1986-04-20', 'M  ', 'mlayfield90@ifeng.com', 'bM9#HS)5m', '1992-01-01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV992229', 'Shawn Bridson', '9670 Logan Place', '0637884935', '1960-05-24', '1985-11-01', 'M  ', 'sbridsondf@intel.com', 'qM9#lnW|X/!8', '2009-11-30', 'NV');

-- Thêm dữ liệu cho bảng KHACHHANG
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH002015', 'Jacenta McCullouch', 'M', '1981-11-17', '0828467463889', '2010-07-29', 'Philippines', '0076041706', 'jmccullouchcs@upenn.edu', '29827 Hansons Pass', 'hO0"~4t!P)', '1983-12-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH004422', 'Jemie Prater', 'M', '1998-04-16', '0683055717214', '2020-05-29', 'Japan', '0177932075', 'jpraterbo@google.co.uk', '014 Crest Line Center', 'lP6&\<VdQM', '1980-10-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH006633', 'Rafaela Giacomelli', 'F', '1966-10-07', '0765687734381', '2014-04-22', 'China', '0500496075', 'rgiacomellic2@kickstarter.com', '810 Forest Dale Junction', 'cO0&8(RGOOQH8kh`', '1981-10-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH008583', 'Ingaberg Hambling', 'M', '1983-02-27', '0313928510752', '2012-08-04', 'Cameroon', '0748910864', 'ihamblingo@sina.com.cn', '9332 Surrey Court', 'aY8{bL1jm|', '1975-06-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH013100', 'Marchall Treffrey', 'F', '1963-09-27', '0717123395466', '2023-11-07', 'Syria', '0517591377', 'mtreffreyaj@alibaba.com', '2 Lillian Hill', 'dX1#)+h4~%)n+y', '1975-01-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH016282', 'Faythe Hayman', 'M', '1961-07-10', '0118983814494', '1965-04-19', 'Russia', '0575614213', 'fhayman47@tiny.cc', '36601 Old Gate Street', 'nZ7)xGM8C6n"d`J', '2000-05-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH017103', 'Gael Gjerde', 'F', '1948-08-20', '0062793209068', '1995-08-21', 'Cyprus', '0229851282', 'ggjerdeb2@bbc.co.uk', '26 Canary Pass', 'yG1`sM<F&0', '1978-01-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH018367', 'Beatrisa Robins', 'F', '1956-04-08', '0004278736570', '1972-07-11', 'Portugal', '0110153585', 'brobins60@gnu.org', '168 Arkansas Place', 'nI3*"&vrsbF8).', '2000-06-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH022658', 'Jerry Court', 'M', '2004-01-01', '0937119404880', '2009-06-27', 'Portugal', '0570802330', 'jcourt1w@themeforest.net', '084 Delaware Terrace', 'kA7<alKjD*kmR}6', '1980-10-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH025130', 'Guglielmo Phillipp', 'F', '1979-03-06', '0614242779910', '1994-02-12', 'Czech Republic', '0216145395', 'gphillipp9k@abc.net.au', '98 Luster Hill', 'fK6$8>oxbWZebZ"', '2018-12-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH027997', 'Carree Couldwell', 'F', '1963-12-01', '0169008138328', '2010-11-12', 'Belarus', '0850710944', 'ccouldwell8h@wordpress.org', '8 Annamark Pass', 'kI8<oA)xhnHF+Ov', '2022-10-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH028582', 'Anton Dyka', 'F', '1953-05-10', '0094061047248', '1998-05-28', 'China', '0801621945', 'adyka7e@yellowpages.com', '878 Jackson Parkway', 'mG8%|UbeT}>OjW', '2024-02-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH029547', 'Angelina Portinari', 'F', '1973-02-25', '0134279115989', '1978-11-14', 'Indonesia', '0993416282', 'aportinari27@google.co.jp', '109 Hooker Road', 'gP9.eN//Nv"M<', '1974-12-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH031990', 'Merilee Sciusscietto', 'M', '1954-01-06', '0873057320583', '1971-05-11', 'Russia', '0376460272', 'msciusscietto6m@myspace.com', '39 Service Street', 'kV8@G?@Hg&i""}kE', '1992-11-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH032071', 'Sheff Bickardike', 'M', '1969-10-23', '0816776543936', '2010-06-29', 'Indonesia', '0913245604', 'sbickardikecp@mashable.com', '18 Haas Way', 'wG4#,>L)pZ5XNf', '2020-08-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH039286', 'Isobel Treasure', 'F', '1955-07-13', '0646501215041', '2003-04-22', 'France', '0249596081', 'itreasureh@bloglines.com', '29104 Warbler Place', 'mY4\3CO_}}g$aA`B', '2000-05-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH041169', 'Julian MacCostye', 'M', '1950-04-12', '0645962525807', '2020-07-15', 'Spain', '0070615559', 'jmaccostyed6@hud.gov', '24560 Troy Crossing', 'gQ2(D(*zDs7xcMN', '2020-06-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH044397', 'Wallis Picton', 'M', '1977-03-24', '0213603632994', '2005-07-03', 'Portugal', '0973801196', 'wpicton3o@arizona.edu', '8 La Follette Junction', 'tE4>8<%SyJ', '1993-07-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH044747', 'Nadya Klugel', 'F', '1984-03-03', '0395469019467', '1988-03-13', 'Finland', '0876673065', 'nklugel78@vistaprint.com', '3531 International Lane', 'uR3*\Db0R"', '1990-03-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH046243', 'Malanie Rennix', 'M', '1945-05-05', '0704560839083', '1992-09-04', 'China', '0781684694', 'mrennix14@purevolume.com', '57880 Sage Road', 'hF6}PME=U77stu', '1997-01-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH052434', 'Nessa Hards', 'M', '1980-04-21', '0116313066053', '1997-08-14', 'Poland', '0712884410', 'nhards9o@vk.com', '7 Vera Place', 'dE3?\ccVQ`k', '2018-03-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH052955', 'Johnath Schinetti', 'M', '1981-04-23', '0418803173109', '1999-09-24', 'Japan', '0915218810', 'jschinettiad@qq.com', '92 Nelson Center', 'jE8>_OH1coZ', '1972-04-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH056342', 'Elmore Drable', 'M', '1984-09-12', '0159705736896', '1986-03-22', 'Indonesia', '0654018512', 'edrable3z@cloudflare.com', '4906 Mockingbird Junction', 'aY1@j@&I', '1976-03-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH057137', 'Lilian Smees', 'M', '1952-02-23', '0375868780212', '1973-11-18', 'Indonesia', '0781030170', 'lsmees98@tinypic.com', '2229 Village Green Center', 'nI7=WJcKS?sO5f)', '2024-03-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH057855', 'Valentino Spruce', 'F', '1954-11-11', '0739977262647', '1970-12-25', 'Belgium', '0917636974', 'vspruce5q@angelfire.com', '5 Reindahl Alley', 'vX8/Fw|cN', '1987-12-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH059888', 'Abdul Brimner', 'M', '1965-01-04', '0909438170980', '1985-05-04', 'Dominican Republic', '0435185851', 'abrimner2e@hc360.com', '893 Springview Point', 'sC2{CIC,8TS0C2', '1987-08-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH065196', 'Pepe Durward', 'F', '1957-10-02', '0857730164844', '1971-11-23', 'Russia', '0424351307', 'pdurwardm@cdc.gov', '51 Scott Circle', 'vP1/pGgwkJNV', '2004-08-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH066621', 'Nevins Romaine', 'M', '1997-11-14', '0566023601518', '1999-09-06', 'China', '0800602874', 'nromaine25@google.co.uk', '11039 Lukken Trail', 'zX3&&v>m&A/Ls,', '2020-09-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH069945', 'Siward Jolly', 'M', '1972-05-03', '0743618097521', '1989-04-22', 'Russia', '0105314368', 'sjolly7@google.ru', '772 Southridge Park', 'xF2}rmvnRb8G=ZAp', '1990-05-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH070493', 'Rowe Gehring', 'M', '1989-12-21', '0744677717089', '1992-12-09', 'Madagascar', '0421134252', 'rgehringal@berkeley.edu', '4 Gateway Lane', 'aW5)#rAsFz>%', '1965-04-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH071341', 'Lexine Conaghan', 'F', '1945-11-18', '0565406693804', '2016-04-28', 'Malta', '0114202756', 'lconaghan3c@blogger.com', '1 Huxley Park', 'vX3*>j>@Cfn', '1964-11-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH079281', 'Norine Nutt', 'F', '1953-06-04', '0278216338696', '2011-08-18', 'Philippines', '0773360814', 'nnutt2h@ftc.gov', '166 Manley Place', 'vY3.J?~%Ym', '2013-03-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH080952', 'Jesse Sterke', 'F', '1985-11-03', '0619406301967', '2014-11-10', 'Colombia', '0034175585', 'jsterkeax@phpbb.com', '4 Holmberg Avenue', 'eB7~pi\AAciNaR6', '1986-08-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH083366', 'Angelina Scogin', 'M', '1960-04-13', '0636079747903', '1989-01-01', 'Russia', '0053563087', 'ascoginc6@parallels.com', '176 Susan Street', 'gX9,P>23iu4Z~U', '2005-12-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH083638', 'Demetris Galbreth', 'M', '1985-04-06', '0872418779203', '1998-08-22', 'Colombia', '0816815777', 'dgalbrethah@aol.com', '3532 Kingsford Hill', 'kT0`GG5D', '2006-11-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084013', 'Bentlee DOnisi', 'F', '1970-08-01', '0724076272555', '1984-02-23', 'Brazil', '0577522788', 'bdonisidt@china.com.cn', '36 Novick Hill', 'sW1/KgWItQ', '1977-09-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084145', 'Inga Wasielewski', 'F', '1995-09-21', '0133187670055', '2004-07-23', 'Philippines', '0662063723', 'iwasielewski4v@nih.gov', '57 Veith Place', 'aU7*8*`w.lPY', '1976-04-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084753', 'Gardie Kimmel', 'M', '1967-06-20', '0425609761406', '1982-05-15', 'Brazil', '0367302459', 'gkimmel2m@merriam-webster.com', '98 Crest Line Pass', 'zF5$SaQR3IYLZSDo', '1988-07-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH085398', 'Flin Burdett', 'F', '1964-02-18', '0582504055382', '1992-11-07', 'Czech Republic', '0712914994', 'fburdett6a@altervista.org', '648 Rutledge Point', 'zZ8>|{\!.jMyo', '1997-03-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH086370', 'Allissa Lorkin', 'F', '1969-08-13', '0100191467047', '2003-12-07', 'Indonesia', '0993389932', 'alorkin88@nyu.edu', '014 Holmberg Lane', 'pB3/w&f2!%O', '2005-07-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH086552', 'Dyann Clardge', 'M', '1988-03-31', '0915213122178', '1993-07-01', 'Mexico', '0374169761', 'dclardge5s@over-blog.com', '90 Messerschmidt Park', 'zM6(2,9&S.f', '1993-03-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH087105', 'Alfi Piecha', 'F', '1963-03-22', '0726110325590', '2021-12-13', 'Republic of the Congo', '0496231277', 'apiecha40@timesonline.co.uk', '506 Browning Plaza', 'fT9!CvA30*~_z.t', '1992-01-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH088786', 'Maxy Klagge', 'F', '1982-09-26', '0002883284939', '1988-07-18', 'United States', '0259150183', 'mklagge6o@seattletimes.com', '0 Nobel Alley', 'vZ5~i>487#Z!', '1975-02-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH094387', 'Cthrine Moylan', 'M', '1991-03-02', '0220902950853', '1993-04-28', 'China', '0491809873', 'cmoylan86@china.com.cn', '03 Melvin Pass', 'pA5.2pDYpe*HE}HH', '2006-06-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH095865', 'Launce MacKay', 'F', '1976-08-24', '0016566926134', '1992-10-12', 'Brazil', '0358112489', 'lmackay3w@twitpic.com', '4686 West Circle', 'hR7}tgX@i', '1976-01-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH096988', 'Gabriella Stanes', 'F', '1975-06-05', '0879651495432', '2007-10-21', 'Syria', '0169537810', 'gstanes95@youtu.be', '0731 Eliot Hill', 'mT8</ue>.SQ', '1992-04-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH098035', 'Nike Lambal', 'F', '1983-05-25', '0992004217815', '2021-11-06', 'Philippines', '0185456261', 'nlambalba@a8.net', '6 Declaration Circle', 'xB1)Dq`3w', '2007-07-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH098418', 'Barde Shopcott', 'M', '1984-12-22', '0857252980170', '2005-08-05', 'Burkina Faso', '0825151693', 'bshopcott4n@cnbc.com', '51 Mcbride Park', 'hF5/<TPcJj', '1979-10-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH099791', 'Pace Pottinger', 'F', '1959-09-27', '0606830030257', '1988-04-18', 'China', '0634140308', 'ppottingerz@qq.com', '71837 Stang Hill', 'jG6''}FO?hFq`', '1969-05-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH099823', 'Bree Wanek', 'F', '1985-07-16', '0665563123180', '1989-03-12', 'Zambia', '0545189589', 'bwanek0@hostgator.com', '76206 Rieder Terrace', 'fN8>%_V#7>', '2005-12-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH104498', 'Lilian Cosson', 'M', '1971-03-01', '0277579681576', '1999-12-03', 'Indonesia', '0121998492', 'lcosson1i@patch.com', '909 Colorado Circle', 'wK5,QQ2fK$2', '1994-08-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH112531', 'Maximilianus Benitez', 'F', '1974-03-16', '0592243993955', '2001-01-19', 'Jordan', '0275630650', 'mbenitezaa@google.com.au', '22556 Boyd Trail', 'dD4\LRn|gcENH!%2', '1963-12-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH116105', 'Horton Ferriday', 'F', '1965-10-04', '0078019598330', '1969-01-28', 'Spain', '0942211119', 'hferriday8f@blogger.com', '03466 Colorado Lane', 'rJ7.p9m&!oj', '2023-01-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH118901', 'Bernetta Beste', 'M', '1957-07-25', '0462667396718', '1977-09-24', 'United States', '0536883006', 'bbestey@techcrunch.com', '7 Esker Center', 'bH8?\yQb&r&', '2007-11-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH119243', 'Kennith Message', 'F', '1947-12-07', '0790357071233', '2007-09-18', 'China', '0573452635', 'kmessageb9@4shared.com', '61 Arkansas Point', 'vX7@sE<W.2i5', '1985-05-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH120054', 'Korella Ratter', 'M', '1945-03-29', '0024357516620', '1997-01-29', 'China', '0650790234', 'kratter4b@boston.com', '5 Karstens Street', 'oB3%.3UT+3', '1965-05-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH121401', 'Patricio Wilmut', 'F', '1947-06-30', '0836003515912', '2005-06-01', 'Poland', '0916014553', 'pwilmut96@list-manage.com', '2 Towne Way', 'iC5!nyN,ve', '2023-04-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH121413', 'Yehudi Shimmings', 'M', '1955-05-13', '0442891264566', '2022-04-08', 'China', '0700365550', 'yshimmings75@tripod.com', '46761 Bayside Hill', 'oB9>`_)Mk<}$Q#e', '1968-12-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH124864', 'Teresita Setterington', 'M', '1958-08-06', '0107782659121', '1985-09-26', 'Peru', '0713898597', 'tsetteringtoncq@state.gov', '09298 Waywood Terrace', 'eU1$yL\7.>u', '1963-09-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH127997', 'Ingelbert Adamthwaite', 'M', '1973-05-16', '0794758231515', '2012-04-08', 'Serbia', '0681192897', 'iadamthwaitecn@icq.com', '46 Kensington Terrace', 'zA9\WKB/sC', '1979-01-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH128339', 'Blondie Van Der Weedenburg', 'M', '1976-04-04', '0115209398763', '1997-09-27', 'Brazil', '0360884344', 'bvanca@craigslist.org', '0 Mosinee Parkway', 'qV1>`Kf5Y', '2008-12-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH128603', 'Ripley Lebbern', 'M', '1964-04-25', '0584958828816', '2002-03-07', 'Mauritius', '0619395639', 'rlebberns@gizmodo.com', '83465 Westridge Plaza', 'uB2?d{9X2(K', '2012-03-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH131158', 'Lexine Brignall', 'F', '1968-10-29', '0991847432892', '1977-04-29', 'China', '0846631376', 'lbrignalldp@skyrock.com', '987 Twin Pines Crossing', 'zV4?W+VQ+b|u', '1981-08-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH132801', 'Ezequiel Larderot', 'M', '1991-10-30', '0515894053122', '1999-04-13', 'Brazil', '0325045443', 'elarderot8z@china.com.cn', '3 Lunder Point', 'tT3_%y(_/.(Us"aE', '1966-07-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH133752', 'Ethelred Glasscott', 'M', '1967-05-18', '0751212168880', '2019-05-03', 'Croatia', '0613660397', 'eglasscottdk@icq.com', '57 Sachtjen Parkway', 'tS6<CP"|e4{=U.h#', '1965-12-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH135574', 'Rutter Gerren', 'F', '1955-04-28', '0216720515148', '2008-08-24', 'Tanzania', '0890861018', 'rgerrenby@themeforest.net', '88876 Mosinee Plaza', 'xO5/`2x?>`#d{L', '1982-12-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH141805', 'Marj Kilmaster', 'F', '1974-06-30', '0486336993886', '1989-04-06', 'Taiwan', '0424622340', 'mkilmaster8e@behance.net', '956 Superior Park', 'dW9qbz,1B', '2005-12-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH145038', 'Kerwinn Bedbury', 'M', '1953-05-05', '0879378649700', '2011-11-05', 'Hungary', '0122409553', 'kbedburyde@google.co.uk', '6 Becker Parkway', 'bC0\_~d}?V#v<b~w', '2022-05-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH146019', 'Valma Cullinan', 'M', '2001-01-13', '0166788071536', '2003-07-04', 'Colombia', '0905009887', 'vcullinan10@craigslist.org', '04470 Fieldstone Drive', 'yM1=i0F+|', '2019-01-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH147192', 'Larisa Lehrle', 'F', '1980-07-02', '0894390032769', '1986-05-19', 'Russia', '0115743373', 'llehrle8a@i2i.jp', '08243 Rowland Hill', 'bA7!3{Ig?.}k', '2011-04-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH149810', 'Michelle Gallear', 'F', '1989-10-17', '0504658724529', '2019-04-06', 'Philippines', '0588638665', 'mgalleardv@over-blog.com', '3 David Place', 'mV3\y`mQJe(O>', '1976-05-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH151736', 'Jandy Klammt', 'M', '1987-08-05', '0837507357356', '1990-11-23', 'Brazil', '0874858506', 'jklammtcd@house.gov', '89 Hallows Avenue', 'zL5/N|pZ', '1997-06-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH153049', 'Betta McOrkil', 'F', '1956-04-01', '0111681192594', '2017-01-23', 'China', '0062190036', 'bmcorkil4r@cbc.ca', '63 Oakridge Pass', 'iZ1\=U8|3N1tVZp', '1988-03-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH154664', 'Aldwin Smallcomb', 'F', '2004-11-11', '0484127094021', '2013-01-05', 'China', '0567110961', 'asmallcombb1@spotify.com', '50 Pond Lane', 'vN3=DjLQ', '1989-07-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH157277', 'Reggy Yegorkin', 'M', '2000-07-07', '0992411044304', '2020-08-28', 'France', '0703573240', 'ryegorkin2r@paypal.com', '9695 Upham Avenue', 'oS1,x#aA.RqQLT=P', '1984-06-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH158297', 'Inge Redit', 'M', '1951-05-03', '0775035888512', '1978-05-22', 'Russia', '0784640013', 'iredit92@blinklist.com', '3 Raven Road', 'jV2|7M`n', '2023-02-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH158688', 'Binny Tiery', 'M', '1949-09-13', '0984332610565', '1980-09-30', 'Vietnam', '0473517401', 'btierybh@zimbio.com', '76 Fulton Center', 'qL2_M!Z8', '2010-04-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH160641', 'Seana Tattoo', 'M', '1973-04-01', '0439769161236', '1981-01-25', 'Russia', '0818751154', 'stattoodr@springer.com', '0 Valley Edge Parkway', 'cM8,>h2bKX6K7y', '2022-10-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH169494', 'Lewie Desseine', 'F', '1954-06-15', '0538312364876', '2019-03-11', 'Philippines', '0872043290', 'ldesseineac@gizmodo.com', '9777 Raven Plaza', 'pD2?fu(K/f12', '1982-12-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH170428', 'Gearard Lavell', 'F', '1971-08-28', '0042064622395', '2010-02-28', 'Philippines', '0242174257', 'glavellb0@symantec.com', '33077 Swallow Circle', 'tV7@~G/E#,yB9D8', '1966-02-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH171568', 'Abie Dionsetto', 'F', '1946-01-20', '0713412206117', '1980-06-12', 'Poland', '0495701578', 'adionsetto8w@cbc.ca', '1334 Merry Alley', 'dS3,Zt)$g.M', '1996-06-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH172746', 'Stanislaw Littlechild', 'F', '1951-12-08', '0133074172170', '2005-09-02', 'Sweden', '0209506779', 'slittlechildbz@msn.com', '331 Canary Plaza', 'qV0!ysxnRz(`0', '1964-12-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH176414', 'Hewe Dryden', 'F', '1955-10-01', '0402487675294', '1972-02-12', 'United States', '0345165618', 'hdrydencg@comsenz.com', '8716 Mandrake Trail', 'dY8|kT7<(', '1964-06-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH177395', 'Janot Punt', 'M', '1978-11-30', '0982352059924', '1981-09-22', 'Indonesia', '0843947220', 'jpunt4i@prweb.com', '609 7th Alley', 'dL9@p8dl*V9y~', '2016-06-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH179505', 'Leon Clewett', 'F', '1953-01-18', '0687658045234', '2003-05-08', 'Norway', '0501502133', 'lclewettd9@umn.edu', '197 Brown Road', 'yF8!n,{bj7SBIE', '2022-03-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH203563', 'Dexter Rekes', 'F', '1986-07-12', '0590629410719', '1992-01-19', 'Greece', '0870169500', 'drekesbu@adobe.com', '2036 Granby Circle', 'zM4)SfE7xy=A', '1993-07-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH204348', 'Ulberto Pearlman', 'F', '1963-11-29', '0032365182314', '1990-12-10', 'Ukraine', '0080516937', 'upearlmancc@ox.ac.uk', '6 Acker Road', 'sX8"_+k(Zb==CnD', '1990-06-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH205161', 'Morty Boulde', 'F', '1974-10-29', '0753434553867', '2002-01-23', 'United States', '0344972341', 'mboulde5i@dell.com', '69 Rowland Lane', 'tB1"BqxsJA8Xj(y', '1973-04-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH205267', 'Mohandas Braunle', 'M', '1967-04-10', '0139363566345', '2010-10-13', 'China', '0357936624', 'mbraunle8c@forbes.com', '9 Kipling Point', 'nI8$VOx=eN/QUCcK', '1992-07-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH206991', 'Melitta Haime', 'F', '1977-08-05', '0291480600110', '1980-04-23', 'China', '0726125271', 'mhaimeam@people.com.cn', '0 Pierstorff Plaza', 'wG6(\yrFSlP', '1979-02-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH213357', 'Ashby Dales', 'M', '1954-09-15', '0564084628819', '1989-09-28', 'Indonesia', '0797050105', 'adales6j@paypal.com', '22 Magdeline Park', 'lW9,_u@"<63R7Yf', '2023-05-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH216038', 'Stephana Turbitt', 'F', '1964-10-29', '0996433054847', '1990-06-05', 'Russia', '0373785910', 'sturbitt82@intel.com', '73 Longview Center', 'qA8}xXjc}h.DP}Y"', '1979-06-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH216186', 'Trev Penner', 'M', '1947-02-26', '0692493183868', '2015-06-28', 'Russia', '0862115960', 'tpennerai@freewebs.com', '0 Ridgeway Point', 'xQ1"YN)opOz', '1986-01-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH221463', 'Reeva Dowry', 'M', '1947-09-16', '0418964491391', '2020-03-04', 'Ethiopia', '0066861945', 'rdowry3i@berkeley.edu', '6856 Arizona Junction', 'oM3,gIZQ', '2009-12-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH225380', 'Aretha McMillan', 'M', '1982-07-31', '0925035989132', '2021-12-17', 'El Salvador', '0287074622', 'amcmillan33@ca.gov', '757 Bunting Crossing', 'gW3>9S56)', '2016-03-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH225914', 'Nanette Macallam', 'F', '1949-05-05', '0710977715618', '2017-10-14', 'Venezuela', '0819760415', 'nmacallam3k@abc.net.au', '1775 Mitchell Alley', 'iS6|Ir7zHwj~8S', '2024-01-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH227910', 'Brody Tretter', 'M', '1966-06-20', '0099318916906', '1974-05-12', 'China', '0299322319', 'btretter6l@cpanel.net', '9366 Moland Street', 'sO9+5g<,,a|raWyQ', '2003-11-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH230361', 'Edmon Rainford', 'M', '1960-09-03', '0564302641040', '2003-07-04', 'Pakistan', '0159522696', 'erainford6t@rediff.com', '894 Glendale Court', 'wS8*La%`fK{?Pn%p', '2001-03-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH231668', 'Cyndia Ambroisin', 'M', '1948-11-22', '0957831655524', '1966-11-23', 'Brazil', '0454838741', 'cambroisin6v@rediff.com', '625 West Lane', 'bN8%<KeW', '1973-04-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH234271', 'Gretel Crutchley', 'M', '1985-02-17', '0364084336699', '2007-10-31', 'Costa Rica', '0491076190', 'gcrutchleyck@nature.com', '03805 Mcbride Terrace', 'aJ9=cZ$lnIb~', '1981-09-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH234451', 'Mischa Lunbech', 'M', '1971-02-23', '0522483430629', '2003-01-06', 'China', '0343994663', 'mlunbech3d@macromedia.com', '3271 Aberg Trail', 'qA5&IVE~l|k', '1986-03-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH235219', 'Ira Andreia', 'M', '1966-09-01', '0255433690146', '1968-05-12', 'South Africa', '0124712237', 'iandreia7x@furl.net', '678 Reinke Drive', 'hE8+I}EhQ', '1997-07-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH236596', 'Grantham Deniskevich', 'M', '1992-02-10', '0193227728159', '2017-08-01', 'Ukraine', '0669909387', 'gdeniskevich69@alexa.com', '411 Toban Way', 'jD6.Y/j3G', '1987-03-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH237192', 'Melly Mulroy', 'M', '1988-05-18', '0612755799388', '2019-11-22', 'Sri Lanka', '0922335045', 'mmulroy3a@irs.gov', '9 Eastlawn Plaza', 'hA1&PSM$E<SG', '1989-12-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH237493', 'Britte Myrkus', 'F', '1977-09-08', '0596719419836', '2003-05-17', 'Japan', '0076113631', 'bmyrkus1n@gravatar.com', '32386 Rieder Place', 'dL8+`f\yShHc', '1972-08-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH237905', 'Chrissy Figurski', 'F', '1952-06-06', '0100088592516', '2017-06-19', 'Mexico', '0869259358', 'cfigurskido@yellowpages.com', '00593 Fisk Terrace', 'yZ7>qG$yl*SqhB', '2017-04-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH241296', 'Bobbye Dogg', 'F', '1974-03-24', '0171710853780', '2005-01-02', 'United States', '0375227349', 'bdogg3t@npr.org', '5909 Cottonwood Court', 'wH8@<=LO<z/', '2009-02-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH243684', 'Thorsten Diplock', 'M', '1950-03-23', '0887213104732', '2019-02-22', 'Thailand', '0570994536', 'tdiplock11@hp.com', '3 John Wall Trail', 'eU2=,a2#Uw(', '2016-12-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH247508', 'Robinet Keems', 'F', '1991-05-01', '0096868041255', '2019-09-08', 'China', '0064868425', 'rkeems1g@chicagotribune.com', '1 Namekagon Trail', 'gL1_K2a8>LADpi5', '1995-11-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH249731', 'Chelsy Wintringham', 'M', '1986-08-11', '0207337967774', '1987-08-03', 'Haiti', '0718069539', 'cwintringhamd4@salon.com', '79287 Spaight Hill', 'gE1\<%Et$}<=J@', '1963-03-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH249737', 'Marissa Huckle', 'F', '1971-09-18', '0703831527626', '2003-08-22', 'Brazil', '0393077493', 'mhucklec9@github.com', '87 3rd Road', 'iE2}E{4Nlh_', '1992-07-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH260266', 'Noak Millins', 'M', '1986-01-18', '0014133166129', '2018-10-25', 'Indonesia', '0114877725', 'nmillins6e@weibo.com', '28 Coleman Parkway', 'sS6%6JlEO!(T"5M', '1963-09-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH271569', 'Richardo Hasson', 'F', '1948-05-02', '0077941900623', '2008-05-23', 'China', '0241538606', 'rhasson5f@umn.edu', '52141 Walton Pass', 'oT9%O`,r', '1983-05-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH274415', 'Elka Brobak', 'M', '1996-10-27', '0259913405178', '2022-08-02', 'Russia', '0689624425', 'ebrobakds@hc360.com', '51841 Maywood Avenue', 'xP8/0BsTX.yHL}>', '1992-09-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH277269', 'Juline Asser', 'M', '1968-08-01', '0616908895514', '1976-01-15', 'China', '0008329468', 'jasserco@wordpress.com', '45 Commercial Place', 'xF0"CcL?"', '1993-12-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH281824', 'Bidget Pooke', 'F', '2000-12-29', '0684746323062', '2020-05-27', 'Uzbekistan', '0816904781', 'bpooke3q@altervista.org', '46 Ridgeview Parkway', 'xD2@8C.\D@#)', '1996-01-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH282109', 'Beltran Ranscombe', 'M', '1982-08-12', '0071744992737', '2009-09-11', 'China', '0881326918', 'branscombe7i@irs.gov', '67 Homewood Terrace', 'pG2#s("1D~)n', '2012-02-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH283594', 'Eolanda Hoyte', 'F', '1973-07-24', '0069078026365', '2014-05-13', 'Ukraine', '0066189246', 'ehoyte3x@twitpic.com', '5 Sachtjen Center', 'dV3+6KA|ny', '2014-07-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH285098', 'Iago Mallall', 'F', '1962-08-06', '0447108623155', '1977-03-04', 'Mexico', '0919871831', 'imallall1v@mayoclinic.com', '36387 Erie Trail', 'uF6?,nVzgG|6R8f', '1985-05-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH285533', 'Alicea Cud', 'M', '1967-08-09', '0703460299628', '2006-11-15', 'China', '0417759767', 'acud1a@behance.net', '5 Vermont Street', 'iH0*j`iz%Q', '1988-08-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH290459', 'Jordana Napthine', 'F', '1997-08-14', '0937499787132', '2019-02-12', 'Sweden', '0638010254', 'jnapthine3u@163.com', '5334 Meadow Valley Place', 'oV5&#KiPI', '2011-08-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH291338', 'Ashby Ruffles', 'M', '1969-12-31', '0486677380705', '2011-01-06', 'Colombia', '0200032792', 'arufflescx@independent.co.uk', '42 7th Drive', 'jP0=MkB_', '2015-06-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH293180', 'Izak Flockhart', 'M', '1956-04-29', '0615845836053', '2018-10-14', 'China', '0413714001', 'iflockhart6n@imdb.com', '61 Warner Crossing', 'nF3~rN"Ef#`', '1983-07-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH296175', 'Stevena Boliver', 'M', '1953-09-20', '0166318845470', '1967-12-27', 'China', '0040057954', 'sboliver3@flickr.com', '32 Southridge Place', 'iG7~TFsb&g1', '1974-02-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH297971', 'Maribel O Scollee', 'M', '1961-10-09', '0563283013681', '2000-07-13', 'Indonesia', '0221110940', 'moscollee2l@com.com', '9 Marcy Alley', 'yR1{0@+RQA~ms8c$', '2001-06-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH301394', 'Karie Leverette', 'F', '1990-12-24', '0076534697703', '1993-02-19', 'Philippines', '0817991350', 'kleverettebj@google.de', '10741 Maple Way', 'vA9%0G*4(C', '1997-01-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH301524', 'Agatha Scotsbrook', 'F', '2004-07-14', '0334492979511', '2009-10-08', 'Portugal', '0189685911', 'ascotsbrook97@scribd.com', '86 Cascade Hill', 'rT4"Rm\a(z,cpI', '2007-10-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH302564', 'Kristi Fownes', 'M', '1952-05-16', '0470233365007', '1970-12-04', 'China', '0813275133', 'kfownesce@etsy.com', '1822 Victoria Hill', 'gC4|stzWx3M"Bq', '1967-11-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH306439', 'Lind Wankel', 'F', '1954-09-19', '0890537337352', '2016-08-19', 'Indonesia', '0600685891', 'lwankel15@sphinn.com', '44 Hanover Trail', 'rU6+/W\b2', '2014-07-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH313588', 'Desirae Alldre', 'M', '1946-01-17', '0442865672952', '1969-06-30', 'Armenia', '0885789894', 'dalldreau@mediafire.com', '9122 Helena Court', 'bH4"plte28y', '2002-12-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH314999', 'Cathleen Patnelli', 'F', '1949-01-18', '0315258219009', '1992-03-09', 'Vietnam', '0351682920', 'cpatnelli1k@stumbleupon.com', '6 Glacier Hill Avenue', 'uW0)MrKeQQrN', '2017-05-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH315582', 'Brit St. Ledger', 'M', '1982-11-20', '0483762060629', '1989-01-21', 'Sweden', '0916335051', 'bst22@i2i.jp', '91 Glacier Hill Park', 'qD8_o/G9C>j1,t3@', '2002-09-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH319135', 'Carmen Virgin', 'F', '1961-07-21', '0926901798013', '2019-06-29', 'Portugal', '0376950322', 'cvirgincj@blogger.com', '65566 Bellgrove Court', 'uZ1,ai`&=nt,3_i|', '1974-03-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH320177', 'Linell Miettinen', 'M', '1998-10-29', '0098719889053', '2016-08-19', 'Syria', '0190037152', 'lmiettinen9c@artisteer.com', '4 Arrowood Road', 'wD0>Z/")i@}*Am}', '2010-01-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH322037', 'Yuri Cuesta', 'M', '1998-01-06', '0974549784456', '2022-01-04', 'Pakistan', '0937690768', 'ycuesta7d@slashdot.org', '77392 Burrows Street', 'hM5?D?J<x~>E', '2001-03-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH330627', 'Hunt Lowndsbrough', 'M', '1960-09-09', '0870942958404', '1997-10-23', 'China', '0132968275', 'hlowndsbrough1x@skyrock.com', '84 Morning Alley', 'kO1(aC{XI', '1967-03-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH334932', 'Archambault Slayford', 'M', '1966-07-05', '0336009281798', '2001-01-10', 'France', '0488422469', 'aslayford16@ftc.gov', '856 Algoma Alley', 'gV2.XQ<f', '1988-05-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH336007', 'Egan Caverhill', 'F', '1966-09-04', '0413134650553', '1983-11-25', 'China', '0389861762', 'ecaverhill6w@twitter.com', '258 Cherokee Plaza', 'hK2%{yy6ck', '2001-10-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH339380', 'Maggee O Neary', 'M', '1946-03-24', '0291592404525', '2015-07-23', 'Chad', '0131674793', 'monearycl@vk.com', '7 Rowland Parkway', 'oP3*/in25c4#pY', '1981-09-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH341501', 'Gaynor Leamy', 'F', '1955-07-13', '0568486167447', '2015-09-28', 'Guatemala', '0060473203', 'gleamy31@addtoany.com', '80097 Birchwood Avenue', 'rK5/OAQ/4r{dtz', '1979-01-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH344217', 'Gerrie Glanvill', 'F', '1980-08-09', '0488188834901', '2005-07-02', 'China', '0464993347', 'gglanvillf@google.pl', '40 Utah Plaza', 'fM9}BRp}uvNa', '1985-12-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH345195', 'Imojean Casham', 'F', '1979-05-18', '0476691212653', '2009-06-01', 'Iran', '0296398773', 'icasham2f@bizjournals.com', '14481 Burrows Crossing', 'rF5(6l|eDqsw', '2022-12-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH347468', 'Bel Suche', 'M', '1955-08-14', '0656701310273', '1975-09-19', 'China', '0177641041', 'bsuche36@tinyurl.com', '95 Brown Plaza', 'wD5}JEwlC|$', '2018-12-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH348292', 'Isahella Beever', 'M', '1958-11-03', '0617262131520', '2010-10-24', 'Peru', '0473652820', 'ibeever2d@smugmug.com', '7846 Kim Way', 'yJ1(wCU3uV2cBR', '2009-10-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH349897', 'Jordan Chatres', 'F', '1985-09-10', '0853039938298', '2009-03-25', 'China', '0471655973', 'jchatres71@sakura.ne.jp', '829 Pond Drive', 'rK5.vqu0x`QIp$Gl', '1986-11-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH350452', 'Brett Dorn', 'M', '1968-11-05', '0838564253331', '2000-08-26', 'Hungary', '0440235096', 'bdorn1z@nymag.com', '2455 Packers Court', 'mL7>rI)9', '1975-07-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH355802', 'Charlton Romain', 'M', '1989-12-10', '0975477664106', '2002-01-03', 'China', '0495876128', 'cromain12@state.tx.us', '5955 Troy Plaza', 'oQ2#A}b&=,tTL', '2014-01-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH358537', 'Lotti Swanne', 'M', '2001-12-18', '0530888709804', '2010-09-13', 'Serbia', '0551674800', 'lswannea4@newyorker.com', '1820 Linden Park', 'oS5.zm\O`gALs', '2014-12-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH362680', 'Morey Greenlies', 'M', '1968-04-14', '0212498802394', '1991-03-07', 'Indonesia', '0775429174', 'mgreenlies2g@a8.net', '0 Talmadge Point', 'xC1<`.V.j$', '2011-12-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH362854', 'Nathalia Marwood', 'F', '1991-01-16', '0117512498427', '2023-10-17', 'Syria', '0207350340', 'nmarwood55@theguardian.com', '9 Oak Point', 'lM4"%$+%T55t6Puy', '1980-03-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH365036', 'Stephani Munkley', 'F', '1984-07-04', '0571769148281', '1995-10-17', 'China', '0015600068', 'smunkley2u@jigsy.com', '44556 Lakewood Pass', 'fO2(1d*Dq', '1977-04-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH366742', 'Waldo Bernhardi', 'F', '1975-06-18', '0316660636278', '2014-09-08', 'Philippines', '0287283765', 'wbernhardibv@fastcompany.com', '708 Drewry Hill', 'pR3&vT*#w', '2015-12-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH370303', 'Valery Babington', 'M', '1978-11-19', '0653664586987', '1983-06-16', 'Russia', '0746556936', 'vbabingtonda@toplist.cz', '95154 Onsgard Avenue', 'eP6%Becu{6<LzZ', '1983-04-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH370775', 'Henryetta Papes', 'F', '1952-05-26', '0650583129936', '1988-11-20', 'Albania', '0194684845', 'hpapes6y@wix.com', '60607 Myrtle Hill', 'tG1\88)ZAM}5=,', '2013-09-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH372608', 'Colver Lightfoot', 'F', '1995-03-03', '0260454034032', '2005-07-07', 'Pakistan', '0851299008', 'clightfootc@technorati.com', '10 Ridge Oak Crossing', 'xD6+Twx1v\gc!QF', '1991-08-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374203', 'Garrik Woonton', 'F', '1959-05-08', '0843374468299', '1994-01-11', 'Russia', '0209477354', 'gwoontondn@miitbeian.gov.cn', '3783 Katie Place', 'wZ7}Y|FWgQN,"', '1996-10-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374389', 'Almeda Goodbody', 'F', '2000-04-06', '0607402428656', '2015-11-18', 'Russia', '0127228617', 'agoodbody30@earthlink.net', '7253 Memorial Terrace', 'jI0}g=IINd', '1999-10-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374822', 'Farley Brilon', 'M', '1971-11-10', '0332186600118', '2010-11-28', 'Senegal', '0789499231', 'fbrilon4l@feedburner.com', '88419 Cascade Center', 'qH4=Jm$g,ElY', '2008-04-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH375073', 'Elbertina Ousbie', 'F', '1976-09-17', '0568986000207', '2003-09-23', 'Indonesia', '0334025545', 'eousbie56@si.edu', '1483 Eliot Junction', 'nB1*Ii1|=Z8.', '2016-12-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH375317', 'Anita Gligoraci', 'F', '1957-08-08', '0385229433811', '2006-03-31', 'Philippines', '0168025341', 'agligoraci2v@hud.gov', '135 Forest Run Road', 'lG7*I_Bh>P4{a4P', '1979-01-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH375794', 'Forrest Aucott', 'M', '1961-05-21', '0807701802998', '1986-01-18', 'Mali', '0982335244', 'faucottaf@infoseek.co.jp', '689 Debs Place', 'jN7#r=Momd', '2013-12-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH376081', 'Biddy Quiddinton', 'M', '1975-01-15', '0076255354850', '2020-05-25', 'Indonesia', '0338771441', 'bquiddinton91@yale.edu', '81 Aberg Parkway', 'kT8{U6W(m9!o&', '1988-11-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH376951', 'Morie Kruschev', 'F', '1955-04-15', '0256613021105', '1997-07-17', 'Benin', '0154711471', 'mkruschevbm@thetimes.co.uk', '9 Veith Parkway', 'fB6(7yYBM', '2004-11-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH378830', 'Andres Moland', 'M', '1955-12-03', '0598959531880', '1989-11-29', 'Brazil', '0188425104', 'amoland9r@list-manage.com', '91731 Comanche Crossing', 'zO7+Y7(=RKU*I', '1981-05-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH380827', 'Silvio Yoodall', 'F', '1972-10-01', '0816196849058', '2006-12-12', 'Czech Republic', '0594765479', 'syoodall64@hao123.com', '5189 Mosinee Parkway', 'kQ0/T?2ir&HK', '2020-01-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH382525', 'Rosanne Mortlock', 'F', '1964-04-30', '0471128400307', '2024-01-22', 'Honduras', '0630482665', 'rmortlock1b@altervista.org', '6 Mosinee Lane', 'eB2(J(uL/xbzS', '1965-12-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH384345', 'Bourke Pantling', 'F', '1969-09-17', '0432360117096', '1993-10-11', 'Indonesia', '0957752126', 'bpantlingaq@163.com', '5 Del Sol Plaza', 'vV0{i}7H2+`X', '1967-10-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH386338', 'Avril Harkins', 'M', '1955-09-20', '0952823241636', '2005-12-01', 'Thailand', '0735806937', 'aharkins4o@dmoz.org', '35 Corscot Park', 'yR2&G.uRF(Ih.~', '2022-01-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH390926', 'August Guterson', 'M', '1988-10-18', '0350968929227', '2007-09-27', 'Kuwait', '0988883220', 'aguterson7k@nationalgeographic.com', '85 Mallory Point', 'xZ2!.Z7I$%Q6l', '2013-11-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH391834', 'Tanitansy Godsafe', 'M', '1947-02-27', '0672715766589', '1988-04-23', 'Portugal', '0085059527', 'tgodsafe8q@ning.com', '77599 Golf Lane', 'yZ6.kF<nuA>,C*/', '1982-03-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH393702', 'Hallie Firman', 'M', '1958-11-18', '0866309135612', '1975-03-03', 'Colombia', '0246575260', 'hfirman17@jalbum.net', '8 Mesta Court', 'mD8_?2qheqV', '1973-02-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH396109', 'Des Goodinson', 'M', '1988-03-08', '0522606628271', '2020-09-15', 'China', '0559735905', 'dgoodinson3m@cbc.ca', '763 Morrow Terrace', 'hG0%4I1ehpht/', '1988-11-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH398577', 'Gypsy Dennick', 'F', '1961-10-26', '0289290867559', '1993-12-03', 'Czech Republic', '0459272725', 'gdennickj@purevolume.com', '03268 Ilene Circle', 'xG8/$gdg', '1976-06-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH398851', 'Carmella Vincent', 'F', '1983-04-21', '0279058105365', '1991-09-14', 'Micronesia', '0398805864', 'cvincent72@weather.com', '02253 Hayes Center', 'wQ3!{2+J(jK', '1998-09-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH407699', 'Dolf Lauderdale', 'F', '1987-01-18', '0517168214039', '1996-04-08', 'Indonesia', '0041408977', 'dlauderdale3p@oaic.gov.au', '000 Portage Junction', 'sB1$1Z65FQn', '1971-04-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH407901', 'Hendrick McGeachie', 'M', '1956-03-23', '0900841858736', '2003-12-12', 'China', '0489830781', 'hmcgeachie4m@squarespace.com', '3 Bartillon Trail', 'yA2"eRoh?HdYO', '1971-04-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH409572', 'Brig Bolens', 'F', '1985-05-06', '0531148583852', '2020-03-26', 'China', '0982555443', 'bbolens5n@imdb.com', '3983 Bay Avenue', 'qJ9!{{pOT$va/', '1998-08-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH414310', 'Vivianna Carr', 'M', '1979-03-02', '0562905812034', '2000-03-29', 'China', '0975339721', 'vcarr4x@hubpages.com', '896 Little Fleur Drive', 'uA4,iTqx', '1995-03-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH418540', 'Perceval Ungerecht', 'M', '1960-01-19', '0590470733550', '1998-07-04', 'China', '0236975790', 'pungerechtd@cbc.ca', '1911 Ridge Oak Pass', 'yU3.onb|&mA.e)m', '2012-11-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH419510', 'Roxy Marshalleck', 'F', '1958-01-11', '0159063696780', '2000-01-31', 'Vietnam', '0944655524', 'rmarshallecka9@ucla.edu', '1 Barby Park', 'zU6?ZyiGPw', '1981-07-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH419726', 'Huntlee Ruffler', 'F', '1992-05-18', '0648614223001', '2024-06-10', 'Brazil', '0275185940', 'hruffler1t@walmart.com', '6605 Village Green Center', 'nE3@qQATR>W', '1988-05-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH425172', 'Hyatt Amsden', 'F', '1965-06-12', '0828715433226', '2002-07-28', 'Philippines', '0989456334', 'hamsden66@sina.com.cn', '04 Springview Plaza', 'kZ2{Hj6?9GX#I', '2013-07-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH428245', 'Dona Pitcaithley', 'M', '1960-07-18', '0731309584863', '2007-10-13', 'United States', '0826421932', 'dpitcaithleya3@guardian.co.uk', '94864 Lawn Point', 'mG1_vBSY*{hPUd_@', '1978-05-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH431206', 'Parnell Oldroyde', 'M', '1977-05-13', '0387518047720', '2019-05-24', 'Czech Republic', '0337746320', 'poldroyde74@thetimes.co.uk', '82462 Westport Circle', 'cE7+q/~D*OdR>0Pk', '1981-10-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH437409', 'Virgil Recke', 'M', '1971-05-17', '0584500414853', '1988-08-25', 'China', '0226158769', 'vrecke1q@flickr.com', '97 Golden Leaf Hill', 'fT5*wn{r>Zz8nR', '1993-08-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH437596', 'Archibald Wais', 'M', '1969-09-13', '0874674587274', '1992-02-11', 'Togo', '0219253050', 'awaisdc@foxnews.com', '22757 Messerschmidt Hill', 'iI5|d{.GYNF9Q', '1975-09-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH441817', 'Hamnet Stockill', 'F', '1981-10-12', '0947957118499', '2006-05-20', 'Japan', '0237544532', 'hstockill7a@odnoklassniki.ru', '18279 Butterfield Street', 'vA4(T<"o9q+gN!um', '1968-08-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH442934', 'Chloe Chadbourne', 'M', '1957-05-28', '0841104848369', '2001-07-09', 'Sweden', '0901541580', 'cchadbournek@tuttocitta.it', '13602 Ludington Point', 'hG8#N4V*@uet', '2007-11-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH446901', 'Monroe Nicholls', 'F', '1949-10-11', '0671002841741', '1989-03-29', 'Russia', '0713773962', 'mnicholls7s@dell.com', '6107 Columbus Plaza', 'yD9$#qfIsG3', '1990-07-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH448966', 'Chrissy Sarl', 'M', '1958-01-31', '0745590064939', '1986-12-15', 'China', '0735231838', 'csarl1d@mayoclinic.com', '9 Springview Place', 'iA38#=Dr', '1991-04-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH451306', 'Suellen Allmark', 'F', '1961-08-08', '0620568372694', '1968-01-26', 'Oman', '0511559641', 'sallmark1j@china.com.cn', '2 Ohio Road', 'bP2)R2\(i)%{>KO', '1996-06-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH453142', 'Rudolf Albasini', 'M', '1990-02-13', '0041643744368', '2006-06-20', 'Germany', '0360297871', 'ralbasini58@foxnews.com', '7 Karstens Street', 'yW2`{Pq9r@(+', '2006-03-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH454006', 'Marlie Gyrgorwicx', 'M', '1958-08-30', '0543743135840', '2006-12-28', 'Bosnia and Herzegovina', '0605587644', 'mgyrgorwicx2i@intel.com', '9 Lawn Road', 'jX3@\nY.6%', '1986-05-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH454423', 'Amalea Bellringer', 'M', '1963-04-10', '0158961378295', '2006-05-03', 'China', '0440226735', 'abellringer3h@vistaprint.com', '2251 Fallview Way', 'nB6<w6yp', '2013-07-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH456126', 'Chancey Welldrake', 'F', '1970-06-06', '0523287873588', '2013-12-31', 'Mongolia', '0066115431', 'cwelldrake26@dropbox.com', '45865 Pleasure Circle', 'sT4`@/Dxb&6', '2022-03-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH456224', 'Jackson Dorney', 'M', '1957-03-02', '0294214703937', '1981-12-08', 'Thailand', '0493971838', 'jdorney5b@topsy.com', '3 Schurz Street', 'mX1@DrJ/2g', '1968-04-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH460521', 'Cross Birtle', 'F', '1964-02-24', '0762486215172', '1983-04-16', 'Netherlands', '0378771876', 'cbirtle73@barnesandnoble.com', '0 Bay Center', 'wG5*XMTHX', '1995-01-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH460998', 'Shawna Smerdon', 'M', '1955-08-18', '0619148048003', '2024-04-06', 'Indonesia', '0294084123', 'ssmerdon4h@nifty.com', '5784 Golden Leaf Drive', 'eH5/LF+K', '1964-12-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH462707', 'Rudolph Islip', 'F', '1962-02-12', '0632089234489', '2018-07-07', 'Poland', '0459437649', 'rislipb@arizona.edu', '4097 Sommers Court', 'dT0`aNS2J?', '2002-04-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH464486', 'Raddie Buxey', 'M', '1953-04-15', '0591324278000', '1991-10-19', 'China', '0575999492', 'rbuxeyd7@51.la', '2 Sheridan Terrace', 'hU1+="ZSrqjc', '1963-07-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH464938', 'Mariellen O Spellissey', 'F', '1977-01-04', '0635867151852', '2019-03-07', 'Poland', '0013198339', 'mospellisseyl@nature.com', '99662 Graceland Point', 'vO1.R+Lrl7`', '1985-07-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH469917', 'Eveleen Lanbertoni', 'M', '1995-11-23', '0186493608757', '2023-09-09', 'Greece', '0988478277', 'elanbertoni6z@noaa.gov', '5 Forest Run Avenue', 'yJ3}IH+r)q$by%', '2007-03-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH473189', 'Imelda Pauling', 'M', '1984-03-22', '0809940062850', '2013-07-18', 'Russia', '0465182226', 'ipaulinga0@unc.edu', '71 Calypso Crossing', 'pK4_C8HHFb\8@0~Q', '2009-02-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH477186', 'Benjamen Epine', 'F', '1994-11-30', '0355653848359', '2016-01-15', 'Tanzania', '0229208695', 'bepinew@google.ru', '68 Fremont Street', 'fF4/Iuw7hZZ%VOr', '2012-02-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH478576', 'Anetta Darinton', 'F', '1953-06-06', '0030967865509', '1972-05-26', 'Russia', '0126256068', 'adarinton8l@nifty.com', '39400 Morningstar Lane', 'jM7+quXh"0(', '2022-09-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH480291', 'Federica Jossum', 'F', '1977-01-24', '0752533898158', '2002-05-05', 'Indonesia', '0957316335', 'fjossum53@gmpg.org', '9 Victoria Avenue', 'vD0*8\}.4>e_7p', '1971-07-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH481886', 'Abdul Bartomieu', 'M', '1948-12-16', '0212735499049', '1988-04-02', 'Portugal', '0482902634', 'abartomieu2b@hatena.ne.jp', '84774 Rusk Park', 'xX4)}lsCjg<}', '2011-08-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH483866', 'Raddy Train', 'F', '1987-04-14', '0522263846211', '2011-07-04', 'Russia', '0526453991', 'rtrain4q@google.com.hk', '88 Blaine Way', 'rQ5$uhm0+VL<hl}', '2003-06-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH486524', 'Whitman Girardez', 'F', '1955-03-22', '0112046791089', '2002-10-19', 'Poland', '0335111549', 'wgirardez1e@cnn.com', '74 Crownhardt Drive', 'jM0,8NlQD8Khx', '1969-08-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH488527', 'Roth Marrian', 'M', '1951-07-16', '0144875643398', '1985-08-21', 'Bosnia and Herzegovina', '0124280075', 'rmarriana@icq.com', '461 Hermina Street', 'eY4@SM@l', '2011-01-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH491026', 'Tamra Lowcock', 'M', '1965-03-20', '0476566245258', '2016-09-17', 'Indonesia', '0774112168', 'tlowcock5e@ucoz.com', '771 Mayfield Point', 'tR8<NnZOm', '1975-06-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH492275', 'Howie Bortolussi', 'M', '1980-08-26', '0136493779766', '2003-11-07', 'Venezuela', '0431720129', 'hbortolussi5k@hp.com', '4 Ilene Drive', 'mO1*)qonXc1z*Ixx', '2004-09-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH494290', 'Rodi Guly', 'F', '1966-07-09', '0579668194791', '1997-02-09', 'Philippines', '0108857540', 'rgulydb@mozilla.org', '3 Hintze Street', 'tZ3#Tb)EJx.Z93>', '1973-04-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH496697', 'Skelly Beet', 'F', '1991-04-13', '0131584554082', '2008-07-05', 'Indonesia', '0844498085', 'sbeet39@google.cn', '45 Logan Road', 'pC2%w3he', '1983-11-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH502528', 'Bendite Conaghan', 'F', '2000-06-03', '0736163185927', '2017-01-01', 'Netherlands', '0218028553', 'bconaghan9e@bloglovin.com', '1120 Fair Oaks Lane', 'aJ0|irzu', '1984-09-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH512913', 'Lion Tissell', 'M', '1969-02-23', '0901118158125', '1996-03-01', 'Georgia', '0708634343', 'ltissell6u@digg.com', '914 Arizona Court', 'lU9.nK`pN3', '2019-06-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH518463', 'Wallis Lopez', 'M', '1945-09-07', '0108478687103', '2022-01-12', 'Portugal', '0921549722', 'wlopez5c@usnews.com', '71523 Lien Point', 'yF6#c6./NJ', '2018-07-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH522691', 'Ninnette Mawtus', 'F', '1986-07-19', '0368604641537', '2011-05-02', 'Russia', '0143481228', 'nmawtus2w@nationalgeographic.com', '04 Namekagon Crossing', 'rH6}3$uLzxvt>J', '1976-10-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH526686', 'Kevyn Cammiemile', 'M', '1966-09-22', '0352280535913', '2012-02-08', 'France', '0649802959', 'kcammiemile4d@dailymotion.com', '08 Victoria Lane', 'mX1`t+)$\OY', '2020-10-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH529157', 'Jock Gravie', 'M', '1969-08-11', '0424257551519', '2018-03-10', 'Albania', '0953228116', 'jgraviebx@ycombinator.com', '2 Loeprich Court', 'pT5/s08E3elEoS}', '1975-06-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH535109', 'Freddi Sommerlin', 'M', '1972-12-03', '0839621425859', '2024-06-23', 'China', '0070546342', 'fsommerlinbe@ezinearticles.com', '5 Petterle Plaza', 'sZ2$X""UUUR', '2003-06-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH536661', 'Brendan Wyre', 'F', '1965-08-23', '0774278605771', '1984-02-06', 'China', '0140607703', 'bwyre32@slashdot.org', '4 Laurel Point', 'tS7>BjNTmj`\7', '1969-09-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH537067', 'Cyndy Cully', 'M', '1950-09-17', '0203263252897', '1982-05-31', 'China', '0540247457', 'ccullycb@cocolog-nifty.com', '905 Shelley Hill', 'uJ4.C<dz+n5NfSU', '2022-05-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH540081', 'Henrik Rubinowitz', 'M', '1990-09-19', '0178726426447', '1991-01-14', 'Indonesia', '0370919353', 'hrubinowitz5v@xrea.com', '3 Scoville Court', 'fH0}=deRg', '1981-06-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH541552', 'Egbert Kitchinham', 'F', '1965-12-07', '0912171536180', '1989-02-26', 'Mexico', '0515820004', 'ekitchinhamc7@comsenz.com', '67038 Cambridge Circle', 'xB64F$@_', '1976-11-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH544891', 'Sargent Bewick', 'F', '1978-10-03', '0755215925572', '2007-05-22', 'Brazil', '0302202006', 'sbewicka6@constantcontact.com', '038 Coolidge Drive', 'uL6$/wpFJ>F2p8n', '2024-04-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545858', 'Claribel Kimmons', 'M', '1979-04-23', '0056893066919', '1983-04-25', 'China', '0122270876', 'ckimmons24@dion.ne.jp', '10980 Clemons Crossing', 'cQ1+ZgCAw$6Q', '2019-07-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545881', 'Fianna Freeborne', 'F', '1950-12-01', '0576824890500', '1965-08-07', 'Indonesia', '0846145355', 'ffreeborne8p@taobao.com', '0654 Graedel Parkway', 'hV3%4M{c,l@3', '2016-03-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545916', 'Cherry Gorden', 'F', '1960-10-16', '0672973963489', '2017-08-03', 'Indonesia', '0847667682', 'cgorden9u@squarespace.com', '9 Fremont Crossing', 'lV9)>Mv?F,)/', '2020-07-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH546066', 'Monti Viveash', 'M', '1986-08-17', '0904532220897', '2014-08-17', 'Indonesia', '0911075126', 'mviveash79@shareasale.com', '1 Crowley Pass', 'kL4/WyZ9', '1976-07-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH547008', 'Lombard Brewitt', 'M', '1950-10-09', '0384827511161', '2020-06-04', 'Nicaragua', '0236480939', 'lbrewitt5u@psu.edu', '9079 Debs Pass', 'cB5)a*PH,O"dc9', '1989-09-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH549396', 'Jorie Holworth', 'F', '1996-02-19', '0009232440530', '2008-04-21', 'Indonesia', '0893950612', 'jholworth59@bloglovin.com', '30575 Maryland Alley', 'jK2|S~R&@S<6', '2006-01-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH553797', 'Rainer Fleote', 'M', '1974-11-05', '0805161135401', '2009-08-09', 'China', '0209326591', 'rfleote3y@nature.com', '7 Ryan Terrace', 'yI6$T{Hh@6I<.', '2022-07-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH554185', 'Vinnie Dendle', 'M', '1983-11-15', '0227857364298', '1995-09-04', 'China', '0244386039', 'vdendle20@icio.us', '9435 Kinsman Pass', 'hW4?ZPU@4O', '2017-08-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH557590', 'Dolores Ineson', 'F', '2002-03-20', '0107313099626', '2013-02-17', 'Indonesia', '0616552208', 'dineson49@tiny.cc', '39815 Orin Road', 'mG3/~u0RVNU@', '1983-05-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH558152', 'Rosemaria Rubinowitz', 'M', '1973-12-29', '0629852635248', '1998-02-18', 'China', '0691216511', 'rrubinowitz63@hp.com', '032 Sunnyside Avenue', 'qQ2_m5rKov4rJ709', '2004-05-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH558718', 'Amos Loudiane', 'M', '1992-10-17', '0870344771442', '1999-06-11', 'China', '0231320447', 'aloudiane2q@phpbb.com', '8602 Talisman Avenue', 'gU7}Aj<Z!qgPy@', '1969-08-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH562909', 'Aaren Gillice', 'F', '1969-10-11', '0619690910231', '1979-04-27', 'China', '0172380260', 'agillicedf@who.int', '1 Briar Crest Circle', 'yV2|f+"Ih6', '2007-01-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH563845', 'Helge Battany', 'M', '2000-03-30', '0916718146704', '2013-05-04', 'Argentina', '0908740460', 'hbattanyi@alexa.com', '1 Loeprich Point', 'sY0/KVY4eJiqje=J', '1970-10-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH563902', 'Earl Hellens', 'F', '1964-01-29', '0927000373535', '1965-01-24', 'Ukraine', '0161979580', 'ehellens2a@upenn.edu', '6 Annamark Trail', 'wH3_O_DQhPxnu', '1999-11-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH564833', 'Jocelyn Lindwall', 'M', '1990-09-11', '0766721296175', '2001-10-21', 'China', '0701890128', 'jlindwall52@privacy.gov.au', '2 Saint Paul Parkway', 'aT3_JWR{CCN&Jx"', '1979-01-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH569847', 'Janith Gabel', 'M', '2002-08-24', '0357480068092', '2014-12-15', 'Yemen', '0606291586', 'jgabela8@google.com.br', '41 Granby Circle', 'xC1<QLCp/Kz#H<', '1995-08-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH574776', 'Bellanca Chanter', 'F', '1961-06-23', '0345444697882', '2009-05-08', 'Canada', '0207226584', 'bchanter8k@google.com.hk', '3884 Schurz Park', 'hU9=2BF=+&2', '1983-09-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH575389', 'Ilene Rochell', 'F', '1967-12-26', '0400175530564', '1979-04-16', 'Indonesia', '0904196173', 'irochelln@phoca.cz', '2022 Del Sol Trail', 'tD0=imL#/$`', '1993-11-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH576265', 'Christian Slafford', 'M', '1948-08-14', '0285928597383', '1974-11-29', 'China', '0477520524', 'cslafford7f@businessinsider.com', '2904 Mitchell Junction', 'qX2{qzQK_$Nb6/S', '2000-04-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH577751', 'Renell Bowater', 'F', '1979-02-09', '0565534840132', '2018-10-05', 'Brazil', '0372067795', 'rbowater5a@prnewswire.com', '82162 Arapahoe Lane', 'lA6?//P((A', '1984-11-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH582692', 'Vail Guerry', 'M', '1978-06-15', '0658397610813', '1983-10-09', 'United States', '0675940226', 'vguerryv@amazon.co.uk', '71816 Beilfuss Parkway', 'tQ7?PuPIskoHJ', '1972-08-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH585269', 'Agnese Station', 'F', '1997-07-14', '0347688188939', '2010-11-07', 'Botswana', '0600094140', 'astationbr@sciencedaily.com', '62627 Mallory Court', 'uD1g!Qq', '1990-12-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH585669', 'Ichabod Shanks', 'F', '1997-07-09', '0062664694635', '2004-10-20', 'Brazil', '0440583824', 'ishanks5t@hubpages.com', '10874 Gerald Point', 'gI9~q~(kwh*B\\Zr', '1967-05-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH591464', 'Alastair Openshaw', 'F', '1966-03-02', '0847859354570', '2007-06-21', 'Pakistan', '0933326381', 'aopenshawcr@samsung.com', '225 Esker Point', 'vZ1be{Ox', '2011-05-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH592532', 'Carlynne O Gara', 'M', '1955-12-01', '0225542688722', '1982-02-15', 'Guatemala', '0343365463', 'co5l@sitemeter.com', '0509 Pankratz Alley', 'zV9)13Z8kT%F.6Qv', '1976-05-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH597520', 'Kayne Grumell', 'M', '1993-11-07', '0063349941051', '2018-04-22', 'Indonesia', '0128604641', 'kgrumell5r@europa.eu', '62 Sugar Plaza', 'zR7`IfY#i', '2010-06-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH599858', 'Doti Egell', 'F', '1960-05-10', '0727399171403', '1983-06-19', 'China', '0275219521', 'degell6c@wufoo.com', '91 Carpenter Lane', 'oT6@eH.8c', '1999-10-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH601439', 'Emmalee Wixon', 'F', '1958-10-31', '0762048263930', '1974-05-15', 'South Africa', '0565949247', 'ewixonak@themeforest.net', '5843 Gina Crossing', 'mC3(72pf5lZ_@,Fx', '2007-12-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH609611', 'Ferdinanda Embling', 'F', '1968-09-27', '0077576925375', '1972-01-01', 'China', '0313702585', 'femblingbn@ucsd.edu', '24962 Logan Park', 'nB0=hv"TF', '2017-03-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH611663', 'Wenona Fruchter', 'F', '1981-01-15', '0808520999785', '2022-02-02', 'Guatemala', '0604831684', 'wfruchter77@slate.com', '18 Sherman Avenue', 'gV4`q`yN+', '1972-10-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH614974', 'Orly Hartwright', 'F', '1965-02-16', '0039075918796', '1972-12-19', 'China', '0732092999', 'ohartwright2o@bloomberg.com', '384 Hooker Pass', 'wY3|uqOL5+bS', '1970-03-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH621641', 'Judah Blewitt', 'M', '1984-04-13', '0465673971557', '2012-12-12', 'Indonesia', '0869623750', 'jblewitt4t@state.tx.us', '813 Old Shore Trail', 'iX6"gCaX?', '2010-05-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH634297', 'Victoir Castiblanco', 'M', '1945-07-20', '0171646512790', '2012-03-13', 'Indonesia', '0079058801', 'vcastiblancobw@prweb.com', '140 Mayer Plaza', 'iA1?vX|?y\>5ns', '2009-09-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH641772', 'Frederick Grix', 'F', '1972-08-14', '0926055373617', '2012-10-27', 'Mexico', '0612432460', 'fgrix8b@ted.com', '140 Hoard Road', 'lS3#6qe*NX', '1980-09-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH647704', 'Maribelle Tortoise', 'F', '1954-11-09', '0620965190063', '2020-01-15', 'China', '0646168333', 'mtortoise43@google.com', '901 Homewood Point', 'nY2<5\BXZIr7', '2023-09-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH651808', 'Elwin Attwell', 'M', '1971-07-17', '0629702754784', '1979-12-15', 'Sweden', '0081213465', 'eattwellb3@example.com', '795 Arkansas Alley', 'xR9\'/L{H0', '1997-02-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH653566', 'Anna-diana Yepiskopov', 'M', '1949-12-11', '0970691747221', '2009-10-19', 'Russia', '0377113556', 'ayepiskopov3v@ftc.gov', '29 Coolidge Circle', 'nJ0}c5S!', '2004-05-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH658936', 'Floyd Stutard', 'M', '1955-07-12', '0001081666370', '2013-06-08', 'Poland', '0034650388', 'fstutard9n@springer.com', '18 Holmberg Center', 'aP2&/y6Yb', '1990-10-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH664884', 'Benedetto Saltman', 'M', '1961-03-24', '0407917929266', '2019-10-26', 'Poland', '0109485070', 'bsaltman9m@trellian.com', '30280 Katie Crossing', 'nL6.S3a4', '1989-08-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH666660', 'Westbrook Woollacott', 'F', '1995-12-08', '0654450772398', '2010-12-17', 'Uganda', '0436481182', 'wwoollacott2k@howstuffworks.com', '90864 Veith Circle', 'jE3_czZ`atgQ', '1972-12-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH667915', 'Francklin Kembry', 'M', '1958-03-10', '0494719762336', '1966-04-08', 'Indonesia', '0304729525', 'fkembry76@miibeian.gov.cn', '690 Darwin Hill', 'dN9.AvbNch*', '2001-03-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH668354', 'Bevin Peschke', 'M', '1991-09-15', '0228317092776', '2023-12-14', 'Ukraine', '0551346183', 'bpeschkedu@tuttocitta.it', '54651 Lyons Road', 'gT2+rr"ry#uL6XdM', '2005-06-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH669019', 'Kylie Messer', 'M', '1967-03-02', '0295249288161', '2020-12-04', 'Czech Republic', '0404626596', 'kmesser7g@mit.edu', '14 Artisan Junction', 'sS5+e2iacr|HS5jB', '1986-10-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH669308', 'Sanders Bremen', 'M', '1948-01-10', '0706869044798', '2015-01-03', 'China', '0186070568', 'sbremen1c@si.edu', '1918 Washington Park', 'vY1bu5!', '1980-02-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH672845', 'Noam Hanmore', 'F', '1980-03-24', '0199846690199', '1999-08-23', 'Dominica', '0886449506', 'nhanmoree@altervista.org', '6461 Vermont Street', 'hV7<QakG+v!!', '1972-07-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH677059', 'Mikaela Connikie', 'M', '1960-07-20', '0133565668460', '2010-08-27', 'Tajikistan', '0965188325', 'mconnikie8o@umich.edu', '2 Vernon Hill', 'fE4?K`Ph~tqwfW', '1966-12-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH682141', 'Gradeigh Newlands', 'M', '1964-02-03', '0986290648071', '2000-10-15', 'Nigeria', '0050335202', 'gnewlandsb8@tripadvisor.com', '20511 Commercial Place', 'rX2@7tCZWQ%x(3%S', '1977-10-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH683530', 'Johny Bugdell', 'M', '1950-09-08', '0818726031766', '1995-06-12', 'Indonesia', '0728833694', 'jbugdell8s@csmonitor.com', '1 Fisk Circle', 'kC7<=|sHAj$?I', '2020-07-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH690162', 'Phyllida Peplow', 'M', '1983-08-02', '0154580588068', '1993-09-12', 'Philippines', '0348943783', 'ppeplow4u@netlog.com', '571 Spaight Point', 'gR1<SX@?rYK~4tF@', '1992-05-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH694938', 'Harbert Olle', 'M', '1965-02-17', '0809610544106', '1992-10-07', 'China', '0015233238', 'holle8m@foxnews.com', '21 Village Green Alley', 'pP6)9vYr!?', '2013-02-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH695437', 'Melodie Askham', 'M', '1953-11-20', '0617615309316', '1966-10-09', 'Bosnia and Herzegovina', '0722337464', 'maskham9x@prlog.org', '760 Eastlawn Parkway', 'qV0"GP8YR', '1988-05-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH696026', 'Colan Keiley', 'M', '1949-11-14', '0692410756108', '2002-09-05', 'Indonesia', '0719891171', 'ckeiley2p@wikipedia.org', '73443 Mifflin Lane', 'bS9.T)w>G', '1992-09-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH697088', 'Cesare Pochet', 'M', '1957-05-12', '0284268915885', '1985-01-24', 'Peru', '0942056149', 'cpochetcm@prlog.org', '59194 Talmadge Trail', 'vF4.#${GViF0', '1996-04-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH697828', 'Joseph Rowler', 'M', '1993-11-23', '0133122374752', '2023-11-05', 'Indonesia', '0292315513', 'jrowlerc8@live.com', '3 Weeping Birch Crossing', 'jM6"ze~!+&.=$i$', '2000-07-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH700174', 'Karlik Dominik', 'M', '1973-12-31', '0264382004508', '2009-03-22', 'Russia', '0447248507', 'kdominik6h@yelp.com', '9367 Maywood Alley', 'fF1+|FHaT', '2005-08-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH706729', 'Ben Ovendale', 'F', '1956-01-25', '0803785463005', '1986-08-27', 'Russia', '0331294254', 'bovendalebt@bloomberg.com', '8201 Porter Hill', 'uG0(9KosnPb', '1969-02-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH707432', 'Opal Petchell', 'M', '1976-06-05', '0388357858806', '2023-01-29', 'Brazil', '0317603892', 'opetchell4w@infoseek.co.jp', '3 Eggendart Drive', 'kZ6}nk+uG&sQ', '1968-07-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH709442', 'Mirelle Grigs', 'M', '1957-04-05', '0466205930683', '1978-08-31', 'Philippines', '0728826512', 'mgrigscy@imgur.com', '6603 Gateway Parkway', 'tD5>liiTz', '1997-03-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH710303', 'Leeland Stranaghan', 'F', '1972-02-26', '0040516775971', '2007-06-23', 'Indonesia', '0007000124', 'lstranaghan6s@walmart.com', '1161 Knutson Place', 'uD2/0!`JeUt6', '1970-05-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH713210', 'Brody Brunt', 'M', '1962-09-14', '0104360306441', '1974-09-11', 'Luxembourg', '0203221771', 'bbrunt99@ucsd.edu', '3218 Truax Point', 'bQ3}RWHOij/A', '1982-04-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH714295', 'Elysha Robertis', 'M', '1953-01-18', '0408044477104', '1971-01-04', 'Bolivia', '0655279367', 'erobertisar@google.de', '2 Novick Lane', 'sF6("6bz', '1987-04-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH714662', 'Fredric Furnell', 'F', '1947-12-22', '0022084214204', '2018-12-03', 'China', '0691540130', 'ffurnell4p@amazon.co.uk', '68 Division Parkway', 'tZ8#L+GCGb|6.GW5', '1963-05-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH716623', 'Barri Rowbury', 'F', '1964-03-10', '0592286683890', '1999-10-08', 'Russia', '0376227133', 'browbury5z@theglobeandmail.com', '305 Mayfield Trail', 'mR1+?{JQ', '1991-09-26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH723964', 'Giff Awcoate', 'M', '1994-05-30', '0802942058913', '2021-10-19', 'Albania', '0745806939', 'gawcoate9w@storify.com', '26828 Carberry Road', 'fO4*$raW', '1997-08-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH724673', 'Nanete Sighart', 'F', '1981-12-16', '0684917771176', '2011-02-15', 'Philippines', '0423430817', 'nsighart6i@sciencedirect.com', '28204 Cordelia Drive', 'aR6<a.Ar#s', '2018-09-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH732493', 'Gayle Bayfield', 'M', '1960-07-08', '0988707615399', '2008-07-06', 'China', '0888102811', 'gbayfield1y@mozilla.org', '001 Birchwood Circle', 'kD1|R<LRm', '1966-02-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH740368', 'Cordelie Caddan', 'F', '1951-02-15', '0236863457518', '2010-03-25', 'Indonesia', '0728606767', 'ccaddanbi@topsy.com', '02 Golden Leaf Crossing', 'lX8|sRPE#=fa*N', '1969-09-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH741003', 'Terri Rasher', 'M', '1986-05-30', '0791715694061', '2018-11-16', 'Indonesia', '0597222563', 'trasherb4@examiner.com', '61 Norway Maple Street', 'zA0?JgbxMH=*', '2004-02-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH741406', 'Waneta Warr', 'M', '1949-07-06', '0934305209339', '2001-02-01', 'Greece', '0389974413', 'wwarr9b@examiner.com', '47 Lunder Plaza', 'vF2/M)o`"', '1997-04-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH748649', 'Carla Gallifont', 'M', '1968-01-13', '0243277130768', '1976-11-24', 'Poland', '0442166936', 'cgallifont48@twitpic.com', '0992 Shasta Parkway', 'xF1(5s68I2.', '1963-07-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH754040', 'Diane Cristoforo', 'F', '1959-07-28', '0012748684230', '2022-08-15', 'Palestinian Territory', '0797196800', 'dcristoforo80@forbes.com', '849 Autumn Leaf Parkway', 'rV4.2F_ns1LqST', '1970-02-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH757285', 'Martie Ringwood', 'F', '1954-09-26', '0573542840110', '1987-09-21', 'China', '0885495679', 'mringwoodt@facebook.com', '14 Hagan Plaza', 'wC7&.3<,Pes', '2023-11-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH760944', 'Allie Valens-Smith', 'F', '1964-02-06', '0583231218661', '1972-09-02', 'Brazil', '0811680769', 'avalenssmithdd@usnews.com', '40 Fairfield Court', 'kL4=kaWe', '1985-03-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH761758', 'Arly Bartlam', 'M', '1956-12-29', '0689809030740', '1965-08-16', 'Russia', '0713332978', 'abartlam85@joomla.org', '8 Hintze Street', 'oO36z/=', '2014-11-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH761950', 'De Mutlow', 'F', '1945-11-07', '0562091703416', '2011-06-10', 'Venezuela', '0295429519', 'dmutlowbl@adobe.com', '0 Acker Hill', 'hT2+{u\Qit4j5&', '1968-09-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH766023', 'Culver Bramall', 'F', '1988-08-11', '0181303746566', '2013-04-14', 'Mexico', '0964284098', 'cbramallaw@home.pl', '935 Cordelia Park', 'rF0{e6=c2R', '2000-02-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH772577', 'Anatole Shemmin', 'M', '1952-06-06', '0953970940998', '1993-06-11', 'Myanmar', '0643009281', 'ashemmindg@freewebs.com', '7473 Superior Parkway', 'mZ9+t@9N(c,v$Y&', '1978-11-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH773285', 'Anthony Klimsch', 'M', '1988-03-29', '0473447519453', '2005-03-22', 'Honduras', '0984429332', 'aklimsch9i@sohu.com', '7 Browning Drive', 'zH5?K06.hv{', '2009-05-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH773307', 'Mirabel Grinyov', 'F', '1950-10-08', '0004158806120', '1978-05-05', 'Finland', '0626173308', 'mgrinyov7o@purevolume.com', '1077 Surrey Place', 'nB6.Qc+u\k#', '2012-07-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH773761', 'Korry Medgewick', 'M', '2002-11-13', '0712354975722', '2010-10-10', 'Morocco', '0452984495', 'kmedgewick28@themeforest.net', '06 Waxwing Trail', 'oY5!L%5D', '1969-10-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH780705', 'Ivette Noads', 'F', '1966-06-26', '0029042595262', '2003-02-05', 'Indonesia', '0102158458', 'inoads1o@baidu.com', '28 Lighthouse Bay Street', 'bI8#u"cX', '2012-02-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH782287', 'Clyve Aronovitz', 'M', '1956-10-01', '0409358186570', '1998-11-20', 'Guatemala', '0212952681', 'caronovitz5w@linkedin.com', '24 Morningstar Junction', 'mO9.fiOps4SH', '2002-02-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH786340', 'Dorene Oakinfold', 'F', '1985-06-09', '0936084323319', '2017-02-13', 'Philippines', '0597284346', 'doakinfold1h@delicious.com', '511 Burrows Trail', 'hX7?#E~eb_6', '1985-12-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH788966', 'Mariette Crawforth', 'F', '1952-07-19', '0635426604434', '1983-08-22', 'Nauru', '0048802491', 'mcrawforth38@gizmodo.com', '32448 Sloan Street', 'jQ9*g(Ae~e', '2011-07-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH790357', 'Larisa Osbaldeston', 'F', '1962-06-22', '0796806099905', '1979-01-28', 'Russia', '0016420547', 'losbaldestonci@wordpress.org', '47 Havey Lane', 'fC8?9~)F', '1967-12-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH791400', 'Reginauld Skipperbottom', 'F', '1956-05-10', '0011480367977', '2017-04-12', 'Egypt', '0838161444', 'rskipperbottom51@about.com', '40 Esker Parkway', 'dB4(L3pe<Q?/}sG', '2008-02-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH791545', 'Demeter Eglinton', 'M', '1949-11-01', '0311632813359', '1978-10-27', 'Sweden', '0376487607', 'deglinton7h@usnews.com', '8 Bartelt Junction', 'fB4#,@F/`KH6G)', '2007-02-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH791759', 'Arvin Arndell', 'M', '1960-08-01', '0361426161927', '1969-01-22', 'Malaysia', '0629742802', 'aarndelldj@alibaba.com', '863 Bunker Hill Crossing', 'wM1%g7O=m*0l', '1963-12-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH796829', 'Gloria Dickins', 'M', '1965-04-18', '0832506092105', '2005-03-05', 'Brazil', '0036407196', 'gdickins5y@ucsd.edu', '64960 Reindahl Junction', 'vH9.od9X=', '2000-07-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH798971', 'Alana Powling', 'M', '1972-02-18', '0418863079953', '2013-05-16', 'Sweden', '0932953270', 'apowling5d@xrea.com', '65 Scofield Avenue', 'mW8+eU3wM7', '1999-09-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH801768', 'Arabela Etoile', 'F', '1965-03-24', '0358730449664', '1988-11-01', 'Ukraine', '0596765197', 'aetoile7t@spotify.com', '817 Maple Circle', 'nR0~1b_4$Xu~$~\%', '1973-12-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH805372', 'Babbie Messenger', 'F', '1992-06-23', '0820520145652', '2001-01-29', 'Honduras', '0722837775', 'bmessenger44@theglobeandmail.com', '6 Center Place', 'bF3~u\vowKJf3>', '1985-06-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH811058', 'Staffard de Amaya', 'M', '1973-05-12', '0393265183428', '1984-05-06', 'Peru', '0919375202', 'sde4z@bandcamp.com', '1590 Glendale Park', 'rP0@y"exb', '2012-08-28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH814108', 'Leonid Bendall', 'F', '1961-12-18', '0540701408040', '1984-06-26', 'Peru', '0229330939', 'lbendall6f@elegantthemes.com', '73694 Melrose Trail', 'uR9+JDT,vuf!PCo', '2023-09-30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH814966', 'Maison Well', 'M', '1963-07-27', '0750489729425', '1992-11-29', 'Ukraine', '0647111516', 'mwell7v@xing.com', '46760 Sugar Avenue', 'tP2,1,\>9DOnc', '2018-11-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH816691', 'Martin Laurenson', 'M', '1948-07-30', '0743411969253', '1977-07-14', 'Poland', '0848371995', 'mlaurenson7n@fastcompany.com', '044 Miller Avenue', 'mI3}#J71\(!}4gC', '1982-07-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH817290', 'Rodie Elgood', 'M', '1960-08-16', '0895559508700', '1983-04-18', 'China', '0595048033', 'relgood3l@shop-pro.jp', '16 Troy Lane', 'sU2<&zkbm', '2001-02-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH819668', 'Tania Slograve', 'M', '1968-06-25', '0402661593678', '1968-09-18', 'Ukraine', '0343252175', 'tslogravebf@ocn.ne.jp', '3 Milwaukee Hill', 'tX3=DfiE>1bh=', '2001-09-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH820199', 'Paulina Redman', 'M', '1965-07-13', '0312564534919', '1982-03-21', 'Czech Republic', '0422788967', 'predman8u@oracle.com', '2012 Rutledge Parkway', 'pZ2>`cHB)zD', '1963-08-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH820633', 'Dunc Quodling', 'M', '1969-10-17', '0165836790977', '1988-09-30', 'Comoros', '0420124372', 'dquodling1m@pinterest.com', '948 Westridge Point', 'hD4`TDp18W9+!', '1993-01-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH823023', 'Ryley Matzel', 'M', '1991-08-13', '0053357478458', '1995-10-26', 'Indonesia', '0002881019', 'rmatzel4@umich.edu', '199 Granby Street', 'xP4"#a)}2VVxO', '1980-08-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH823647', 'Kenyon Janny', 'F', '1954-02-11', '0964845446458', '2001-07-09', 'Portugal', '0315365573', 'kjanny3n@tuttocitta.it', '735 Maple Wood Point', 'eA5`SO#', '2008-01-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH828458', 'Antin McMenamy', 'F', '1997-04-12', '0336031332841', '2002-04-23', 'China', '0643739954', 'amcmenamy7l@de.vu', '0 Maywood Circle', 'eI2/Fuy', '1972-02-24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH830363', 'Rodi Sacchetti', 'M', '1974-06-04', '0263977073370', '2019-01-09', 'Brazil', '0109781694', 'rsacchetti9p@examiner.com', '5 Valley Edge Crossing', 'eP7%w|2b.o{', '2023-07-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH832329', 'Fara Sheringham', 'F', '1948-12-10', '0538359681442', '1997-05-04', 'Philippines', '0960118208', 'fsheringhamd3@ibm.com', '87188 Russell Lane', 'zO3?ub=iSy<$4', '1971-08-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH842523', 'Farrah Deaton', 'M', '1974-05-22', '0634556373724', '2007-06-11', 'Guatemala', '0510117905', 'fdeaton87@economist.com', '195 Carey Point', 'vQ3(2x7<', '1990-04-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH847284', 'Odessa Jelks', 'M', '1965-11-07', '0958047268160', '1999-04-24', 'Ivory Coast', '0141268085', 'ojelks7j@admin.ch', '31 Ohio Plaza', 'cZ5`<_=K_(=X9', '1964-12-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH857208', 'Falito Gerding', 'M', '1973-05-27', '0837601389982', '2013-02-03', 'Russia', '0290223449', 'fgerding1r@answers.com', '9 Spohn Circle', 'nQ2}q,AZ>', '1991-06-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH859460', 'Benjamen Stallwood', 'F', '1945-04-06', '0055474555924', '2024-04-08', 'Sweden', '0084777016', 'bstallwooddh@mapy.cz', '18633 Stang Circle', 'pZ7$fRN3b', '1972-09-29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH860169', 'Trish Flemyng', 'M', '1986-08-07', '0038980220517', '2009-10-17', 'China', '0022606452', 'tflemyngg@icq.com', '9969 Glendale Place', 'bM9"@D"TGYQpIhx', '2021-12-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH862046', 'Carlyn Sabathe', 'M', '1991-02-02', '0844391851100', '2000-10-20', 'Poland', '0319931207', 'csabathe3g@soundcloud.com', '2492 Troy Avenue', 'hZ2,5f5Qs1v,7i', '2004-01-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH863030', 'Ariella Kedie', 'M', '1955-04-11', '0053941117097', '2008-09-15', 'Philippines', '0418309974', 'akedie7z@facebook.com', '529 Waubesa Avenue', 'eI4)YIl0', '2002-10-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH867105', 'Caryn Duncan', 'M', '1976-11-12', '0785119687909', '2008-11-22', 'Yemen', '0147011365', 'cduncan2x@google.co.jp', '55 Grover Drive', 'cA9#7XPI&sUBK,=~', '2001-04-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH868676', 'Kati Clout', 'M', '1949-01-21', '0649193121086', '2015-02-10', 'Mexico', '0828057276', 'kcloutb5@phpbb.com', '942 Union Lane', 'rR1"@r6SeMpd59', '1963-11-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH870175', 'Josh Fitzsymonds', 'F', '1954-05-03', '0278863688240', '2020-05-23', 'China', '0690705001', 'jfitzsymondsc0@163.com', '97428 Forest Run Way', 'xY0*A65|u_', '1966-04-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH870922', 'Darwin Palluschek', 'M', '1948-03-13', '0193492147249', '2006-01-03', 'China', '0416606161', 'dpalluschekct@amazon.co.jp', '07 Blackbird Court', 'pA3<fYZxJv%yEu{X', '2022-05-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH872145', 'Joly Laskey', 'M', '1969-10-14', '0226563977596', '2010-11-18', 'Norway', '0168626995', 'jlaskey90@wikia.com', '7 Kingsford Lane', 'zG3?uVe5H|*!Q~', '1980-11-06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH876167', 'Zorana Cronk', 'M', '1997-05-15', '0757265893837', '2007-05-12', 'Moldova', '0978164433', 'zcronkc1@census.gov', '72141 Bluejay Parkway', 'kY7?lz!', '1967-12-25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH877635', 'Dolli Swindlehurst', 'M', '1960-09-18', '0256567735907', '1991-03-14', 'Serbia', '0302494718', 'dswindlehurst34@paginegialle.it', '4 Colorado Point', 'fQ1?|+id3NMFvd', '1990-10-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH884843', 'Joana Pantlin', 'M', '1948-05-18', '0441379940741', '2023-07-03', 'Indonesia', '0877286761', 'jpantlin21@blogspot.com', '40 Norway Maple Alley', 'pJ1!8OH9', '1963-08-19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH895693', 'Ree Maudett', 'F', '1970-03-16', '0788893313054', '1992-12-25', 'Thailand', '0593586368', 'rmaudettp@networksolutions.com', '319 Fulton Junction', 'vO3$*n=v', '2012-12-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH896229', 'Carmon Panther', 'F', '1960-04-16', '0586492148977', '1970-03-17', 'China', '0202934816', 'cpanther50@cnet.com', '14003 Hermina Street', 'fN8/v`gHw%', '1978-12-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH900537', 'Killie Jaszczak', 'F', '1985-05-19', '0471380548937', '1993-12-25', 'Philippines', '0088860502', 'kjaszczak84@vistaprint.com', '63 Onsgard Alley', 'zX7_Q}l*e', '1989-10-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH903096', 'Ardelle Burlingham', 'M', '1955-01-30', '0157918577999', '1974-04-06', 'Philippines', '0839455425', 'aburlingham45@symantec.com', '1 Sheridan Crossing', 'wQ9|)K<q#', '1988-05-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH904366', 'Idaline Deverall', 'F', '1989-12-25', '0783585587426', '2010-09-28', 'Russia', '0756069376', 'ideverallao@va.gov', '9 Amoth Terrace', 'uP6"Li4(l', '1979-12-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH907558', 'Kristin Oswald', 'M', '1950-05-23', '0280107467228', '2010-11-13', 'Czech Republic', '0471886935', 'koswald5o@nytimes.com', '09152 Ohio Way', 'aI6&3s=E=NH|?I22', '1992-11-02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH909409', 'Jeffrey Creevy', 'M', '1987-03-29', '0055180280282', '2008-04-22', 'Croatia', '0037465535', 'jcreevyag@senate.gov', '0748 Bluestem Street', 'xS4*25\(u~', '2014-10-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH910997', 'Oliver De Roberto', 'F', '2001-03-22', '0199960549551', '2019-04-22', 'Madagascar', '0995666013', 'ode5p@nature.com', '09 Golf View Way', 'bR4+2fcZ', '1965-03-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH914683', 'Lezlie Vest', 'M', '1993-05-04', '0767202324407', '2016-07-14', 'United States', '0446613518', 'lvest1f@reverbnation.com', '06 Lindbergh Street', 'qI4+Mp7uY@Fw3<', '2002-05-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH919695', 'Hermie Balcon', 'M', '2002-10-13', '0447122195834', '2009-05-12', 'Vietnam', '0646016445', 'hbalcon9z@chron.com', '75882 Grover Park', 'kL6$dGd5XZ<7h', '1984-05-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH920085', 'Nevile Williscroft', 'F', '1988-02-28', '0519141090527', '2020-02-23', 'China', '0606036806', 'nwilliscroft8r@rambler.ru', '7 Harper Way', 'eP0`P7?c9>0', '2003-12-01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH922933', 'Anatola Ettridge', 'F', '1956-03-26', '0186788095251', '1965-07-23', 'Czech Republic', '0261838915', 'aettridge9g@dyndns.org', '88641 Nova Center', 'jQ1?},RK', '2010-10-31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH929292', 'Sonny Fried', 'M', '2000-08-25', '0416994728524', '2009-08-29', 'China', '0277501288', 'sfrieddm@symantec.com', '72495 Granby Park', 'vP0>>&~nzUG3a=$', '1977-11-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH934191', 'Tyrus Boater', 'F', '1963-06-14', '0777124941608', '1987-10-20', 'China', '0905494299', 'tboaterq@amazonaws.com', '0 Oakridge Road', 'rF4}4\'A!=*', '1995-11-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH935820', 'Darius Mulliner', 'M', '1956-11-08', '0170040891714', '1982-12-06', 'Egypt', '0179201194', 'dmulliner83@cyberchimps.com', '5 Mitchell Circle', 'yC5|tW$x2{Mg\s`', '1985-01-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH936121', 'Dominica Bagnold', 'F', '1967-02-15', '0987148836062', '1995-01-03', 'Sweden', '0201136768', 'dbagnold5g@craigslist.org', '94332 Green Street', 'mZ5>T/<%t', '2023-04-27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH936694', 'Trish Coules', 'F', '1979-07-11', '0288532947461', '1997-08-20', 'Nicaragua', '0636623724', 'tcoules8d@theguardian.com', '481 Manley Circle', 'dQ3!H3d.', '2016-03-04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH939840', 'Trudy Bannell', 'M', '1968-02-10', '0072075561830', '2006-12-10', 'Portugal', '0840821999', 'tbannell2j@intel.com', '965 Columbus Parkway', 'jE2+(H6VD', '2005-09-13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH941652', 'Fraser Bevan', 'M', '1970-08-20', '0575297304296', '2002-04-11', 'Poland', '0769206838', 'fbevancv@cocolog-nifty.com', '56 Straubel Park', 'sO2%xAMW?q', '1989-01-15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH944491', 'Jeannine O Lone', 'F', '1946-06-04', '0374153637000', '1989-07-28', 'Colombia', '0762656546', 'jobg@youtube.com', '88 Old Gate Alley', 'qJ7*ghyE93L', '1972-05-08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH945522', 'Ninetta Paler', 'M', '2003-08-24', '0940394990020', '2021-07-02', 'Senegal', '0489380515', 'npaler3b@com.com', '1201 International Parkway', 'oU0$\Dxy1nJ/XwU', '1980-07-21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH947121', 'Elga Gayler', 'F', '1955-04-17', '0111340817879', '2017-11-15', 'Peru', '0613837231', 'egayler9y@census.gov', '47945 Waywood Point', 'qN6#8rmQp', '1976-08-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH949184', 'Isa Nobes', 'M', '1983-09-07', '0380192346951', '2014-09-09', 'Malaysia', '0016696264', 'inobesdi@nationalgeographic.com', '2 Veith Place', 'vM9/uRD`!(T.*#Wi', '1979-01-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH949953', 'Mariquilla Whiteland', 'F', '1961-12-19', '0545208581597', '1990-03-18', 'Venezuela', '0487110341', 'mwhiteland9@scientificamerican.com', '78722 Tennyson Court', 'aD8?1hN&(,p', '1972-08-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH951882', 'Ursuline Ewen', 'F', '1978-09-28', '0329886045799', '2008-01-06', 'Brazil', '0879505059', 'uewen7w@mapquest.com', '79479 Burrows Crossing', 'yI1?$1J4', '1969-09-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH957276', 'Hyatt Bilbery', 'M', '1952-10-11', '0959838546239', '2023-12-19', 'Portugal', '0304644037', 'hbilberydl@miibeian.gov.cn', '9 Fairfield Terrace', 'lY1{&xKP4rpV<KT', '2023-09-10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH958880', 'Emmie Fishbourne', 'M', '1950-09-21', '0502049640910', '1995-04-04', 'China', '0109166216', 'efishbournea2@liveinternet.ru', '315 Little Fleur Hill', 'tQ6\|XAPQP49A', '1980-11-22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH965543', 'Juliann Bachelor', 'F', '1961-05-05', '0695965679483', '1975-02-13', 'Philippines', '0212882266', 'jbachelor6r@state.gov', '1 Forest Dale Hill', 'oO0?dFEQtVx', '1979-04-18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH971165', 'Anabelle Charlin', 'M', '1991-01-11', '0333054426366', '2006-02-28', 'United States', '0238988154', 'acharlin5x@twitpic.com', '79 Hudson Avenue', 'iM4&Ps=0.7!>%Ly/', '1994-11-05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH975326', 'Laney Penke', 'F', '1972-02-16', '0215833381081', '1992-09-14', 'Japan', '0890953845', 'lpenke6b@g.co', '3 Mccormick Road', 'aU7}<J@{kW1q', '1991-02-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH977771', 'Agnes Orteaux', 'M', '1952-02-20', '0612174501441', '1995-07-02', 'Russia', '0286035214', 'aorteauxx@google.co.jp', '827 Jenifer Plaza', 'tC7)i2!f\"Rch3', '1966-01-16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH978474', 'Robina Cason', 'F', '1984-05-21', '0319796159705', '2011-04-11', 'Philippines', '0432135511', 'rcason6p@unicef.org', '8 Muir Crossing', 'fD7?\tMx9dX#?w#', '1967-05-03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH980984', 'Olga Sparwell', 'M', '1955-04-24', '0105143308044', '2008-10-13', 'Indonesia', '0927499626', 'osparwell4f@seesaa.net', '4 Park Meadow Junction', 'iU9\Z._t!)>.F=', '2000-09-20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH984343', 'Hamlen Espada', 'M', '1976-12-06', '0558353389103', '1977-11-01', 'Philippines', '0315827654', 'hespada6d@businesswire.com', '66 Pleasure Point', 'nF8_N&4ye.8)u~Yn', '1984-07-07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH986650', 'Lina Lindemann', 'F', '1966-10-30', '0141424864333', '2004-03-23', 'Indonesia', '0191819274', 'llindemannat@miitbeian.gov.cn', '6 Miller Center', 'tO1{i,kqVC5cK', '1999-09-09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH987019', 'Alleyn Massimi', 'F', '1953-03-27', '0756206498260', '2014-08-14', 'China', '0570251570', 'amassimi9v@hexun.com', '11961 Michigan Point', 'tU1_+w7CZ<M?Rv', '1978-06-17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH987796', 'Langsdon Ghilks', 'F', '1977-03-05', '0774105643588', '1980-11-17', 'Burkina Faso', '0502926800', 'lghilks4c@godaddy.com', '9 Hanover Alley', 'jX1@hJO{0', '1976-04-23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH988988', 'Bobbie Slowly', 'F', '1978-12-14', '0622121037365', '2013-05-07', 'China', '0063619708', 'bslowly8j@xrea.com', '093 Fairview Lane', 'mX0_<B/z5wOn#4Z', '2018-03-11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH992165', 'Cheri Acock', 'M', '1956-02-01', '0458213828692', '2014-03-06', 'Indonesia', '0576025290', 'cacock68@angelfire.com', '7 Jay Junction', 'yJ1?,W2uXYd', '1977-04-14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH993336', 'Karita Narducci', 'F', '1988-06-10', '0880534107117', '1991-07-05', 'Estonia', '0112990130', 'knarducci4j@prlog.org', '06 Declaration Court', 'wV8&xf.@/k?8ZR{', '1970-09-12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH995610', 'Kirsteni Spiby', 'F', '1967-06-12', '0925673149037', '1973-03-20', 'China', '0349044034', 'kspiby65@yahoo.com', '97122 Loeprich Circle', 'iQ2#sWWz0$1v1k', '1965-11-23', 'KH');

-- Thêm dữ liệu cho bảng HOADON
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00000001', 'NV078538', 'KH496697', '2024-05-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00130557', 'NV078538', 'KH370303', '2023-06-14', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00140987', 'NV430597', 'KH004422', '2024-02-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00438831', 'NV376524', 'KH437409', '2024-06-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00614964', 'NV325416', 'KH870175', '2023-10-11', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00921927', 'NV634749', 'KH941652', '2023-04-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01293073', 'NV281921', 'KH823023', '2023-08-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01357061', 'NV392010', 'KH554185', '2023-12-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01373041', 'NV477238', 'KH993336', '2024-07-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01616005', 'NV659671', 'KH454006', '2024-11-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01977459', 'NV849197', 'KH344217', '2023-02-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('02704470', 'NV068235', 'KH496697', '2023-10-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('02998601', 'NV289904', 'KH350452', '2024-06-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('03227540', 'NV639320', 'KH160641', '2024-02-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('03909266', 'NV425018', 'KH044747', '2024-11-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04083258', 'NV308774', 'KH362680', '2023-04-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04356983', 'NV610092', 'KH290459', '2024-01-18', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04537853', 'NV240973', 'KH039286', '2023-02-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04581995', 'NV160815', 'KH772577', '2024-03-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04679087', 'NV775515', 'KH947121', '2024-01-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04828666', 'NV454412', 'KH147192', '2024-10-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04858972', 'NV634749', 'KH483866', '2024-02-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05076247', 'NV540497', 'KH370303', '2023-02-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05146450', 'NV453523', 'KH297971', '2024-11-20', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05346638', 'NV098182', 'KH441817', '2024-05-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05396256', 'NV271794', 'KH919695', '2023-07-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05396895', 'NV787213', 'KH071341', '2023-03-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05469109', 'NV481500', 'KH293180', '2024-06-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05475100', 'NV391581', 'KH225380', '2024-07-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05502162', 'NV019077', 'KH355802', '2024-05-13', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05527832', 'NV444738', 'KH085398', '2023-09-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05596399', 'NV447108', 'KH419510', '2023-09-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05949964', 'NV367893', 'KH469917', '2023-02-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06058572', 'NV732368', 'KH099791', '2023-03-25', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06062676', 'NV941879', 'KH437409', '2023-11-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06132492', 'NV012052', 'KH666660', '2024-08-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06225856', 'NV539311', 'KH582692', '2023-03-09', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06317278', 'NV822716', 'KH895693', '2024-02-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06995735', 'NV945233', 'KH903096', '2023-02-26', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07129158', 'NV372709', 'KH707432', '2024-08-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07199807', 'NV925832', 'KH297971', '2023-03-31', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07542827', 'NV797940', 'KH013100', '2024-11-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07854851', 'NV441589', 'KH828458', '2024-11-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08184228', 'NV012052', 'KH237905', '2023-02-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08391580', 'NV675961', 'KH987019', '2024-06-11', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08437144', 'NV444738', 'KH131158', '2024-03-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08617294', 'NV740277', 'KH945522', '2024-09-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08669987', 'NV303199', 'KH469917', '2023-11-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08846928', 'NV955988', 'KH791759', '2023-12-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08986110', 'NV262355', 'KH237905', '2023-08-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('09685222', 'NV675961', 'KH057137', '2024-12-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('09860333', 'NV582109', 'KH658936', '2024-04-30', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10106971', 'NV440528', 'KH876167', '2023-10-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10174845', 'NV850038', 'KH339380', '2024-07-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10179483', 'NV079311', 'KH349897', '2023-08-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10935131', 'NV098182', 'KH274415', '2023-10-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('11057658', 'NV189822', 'KH016282', '2024-11-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('11821755', 'NV481500', 'KH554185', '2023-04-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('12038966', 'NV047107', 'KH428245', '2024-06-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('12593587', 'NV303894', 'KH460998', '2023-11-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13227974', 'NV787213', 'KH929292', '2024-01-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13528822', 'NV325416', 'KH977771', '2024-03-04', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13740822', 'NV440528', 'KH358537', '2023-11-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13933332', 'NV540497', 'KH714295', '2023-10-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14069840', 'NV308774', 'KH121401', '2023-08-21', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14258585', 'NV189822', 'KH056342', '2024-03-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14930507', 'NV158614', 'KH842523', '2023-07-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14979073', 'NV019077', 'KH375073', '2023-06-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15076148', 'NV856226', 'KH666660', '2024-03-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15095037', 'NV619570', 'KH083638', '2024-07-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15139654', 'NV105604', 'KH008583', '2023-11-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15250752', 'NV850462', 'KH375073', '2023-03-31', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15308723', 'NV894914', 'KH365036', '2024-11-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15324566', 'NV413814', 'KH980984', '2023-03-24', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15422881', 'NV010574', 'KH271569', '2024-08-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15662805', 'NV453523', 'KH347468', '2023-11-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15902113', 'NV073871', 'KH179505', '2023-09-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16103611', 'NV019077', 'KH176414', '2023-12-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16346188', 'NV735464', 'KH995610', '2024-09-04', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16456492', 'NV592137', 'KH772577', '2024-10-09', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16466095', 'NV770980', 'KH585669', '2023-12-01', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16531754', 'NV193026', 'KH741406', '2024-12-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16573625', 'NV738399', 'KH017103', '2023-03-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16752375', 'NV850462', 'KH065196', '2024-07-04', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17056136', 'NV955885', 'KH492275', '2024-03-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17168656', 'NV240888', 'KH951882', '2023-08-11', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17178530', 'NV078937', 'KH823023', '2023-01-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17198837', 'NV193469', 'KH723964', '2024-12-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17387584', 'NV092108', 'KH234451', '2024-02-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17443686', 'NV193469', 'KH104498', '2023-04-11', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17506861', 'NV447108', 'KH558718', '2024-09-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17542571', 'NV059671', 'KH668354', '2023-06-20', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17815063', 'NV240888', 'KH919695', '2024-07-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18045997', 'NV193026', 'KH079281', '2023-09-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18162373', 'NV343692', 'KH302564', '2023-02-15', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18169248', 'NV242498', 'KH820199', '2023-09-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18226382', 'NV160815', 'KH442934', '2023-03-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18282997', 'NV308774', 'KH716623', '2023-11-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18517549', 'NV078937', 'KH723964', '2023-03-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18580663', 'NV945233', 'KH132801', '2024-12-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18719517', 'NV012052', 'KH052434', '2024-03-20', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19014083', 'NV277291', 'KH592532', '2024-11-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19249690', 'NV592137', 'KH641772', '2024-02-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19315538', 'NV790581', 'KH669019', '2023-06-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19453685', 'NV979641', 'KH773761', '2024-04-03', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19580154', 'NV539311', 'KH099791', '2023-07-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19594779', 'NV747397', 'KH535109', '2023-10-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19761714', 'NV890913', 'KH339380', '2023-06-09', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20013655', 'NV945233', 'KH526686', '2023-11-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20049535', 'NV659802', 'KH988988', '2023-07-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20161572', 'NV201665', 'KH084753', '2024-09-21', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20391629', 'NV339957', 'KH945522', '2024-06-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20502716', 'NV240888', 'KH904366', '2023-03-28', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20765138', 'NV415824', 'KH919695', '2023-04-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20852482', 'NV645678', 'KH169494', '2023-03-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21000317', 'NV047107', 'KH057137', '2023-10-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21047967', 'NV077006', 'KH460998', '2024-04-22', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21156781', 'NV044506', 'KH683530', '2023-05-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21163258', 'NV477238', 'KH690162', '2024-02-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21702680', 'NV888660', 'KH370775', '2024-05-23', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21932175', 'NV481500', 'KH713210', '2023-07-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22170126', 'NV450177', 'KH545916', '2023-11-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22234337', 'NV955988', 'KH283594', '2023-11-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22376000', 'NV639320', 'KH462707', '2023-08-23', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22398445', 'NV234271', 'KH057855', '2024-09-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22535180', 'NV047107', 'KH667915', '2023-05-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22610247', 'NV336685', 'KH227910', '2023-03-15', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23127223', 'NV376524', 'KH884843', '2024-09-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23187054', 'NV711456', 'KH141805', '2024-08-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23273614', 'NV711456', 'KH895693', '2024-02-04', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23558474', 'NV044506', 'KH714662', '2023-04-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23760940', 'NV325416', 'KH641772', '2023-06-09', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24139505', 'NV440528', 'KH213357', '2023-08-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24243157', 'NV717819', 'KH599858', '2024-07-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24456745', 'NV289904', 'KH872145', '2023-08-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24665394', 'NV550817', 'KH862046', '2023-09-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25142090', 'NV288830', 'KH008583', '2024-04-30', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25397161', 'NV487204', 'KH176414', '2024-09-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25535597', 'NV308774', 'KH554185', '2024-05-31', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25788579', 'NV659671', 'KH895693', '2024-03-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26010133', 'NV955885', 'KH782287', '2023-01-25', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26677987', 'NV391581', 'KH227910', '2023-11-30', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26787626', 'NV634749', 'KH575389', '2023-09-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26815410', 'NV441589', 'KH791545', '2024-05-01', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27030355', 'NV496066', 'KH398577', '2024-08-29', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27091561', 'NV660753', 'KH098035', '2024-07-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27332016', 'NV024982', 'KH576265', '2023-02-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27447085', 'NV659802', 'KH949953', '2024-08-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27661857', 'NV619036', 'KH348292', '2023-02-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28151554', 'NV905823', 'KH814966', '2023-10-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28318408', 'NV415824', 'KH576265', '2024-05-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28322578', 'NV193469', 'KH694938', '2023-05-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28492331', 'NV078538', 'KH084753', '2024-06-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28670724', 'NV439113', 'KH621641', '2023-11-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28702515', 'NV901134', 'KH558718', '2023-09-25', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29226413', 'NV019077', 'KH575389', '2024-07-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29345459', 'NV325416', 'KH714662', '2023-09-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29346466', 'NV832790', 'KH562909', '2023-10-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29358314', 'NV180911', 'KH442934', '2024-05-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29381800', 'NV921688', 'KH545916', '2023-12-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29405833', 'NV634749', 'KH025130', '2024-07-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29440514', 'NV376524', 'KH667915', '2024-12-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29790005', 'NV619036', 'KH585269', '2023-10-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29967804', 'NV539311', 'KH344217', '2023-06-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29988531', 'NV025466', 'KH230361', '2024-09-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30260503', 'NV894914', 'KH285533', '2023-04-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30347601', 'NV890100', 'KH234271', '2024-02-04', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30477187', 'NV650538', 'KH344217', '2023-03-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30797850', 'NV425018', 'KH761950', '2023-03-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31100814', 'NV303894', 'KH554185', '2023-09-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31206330', 'NV992229', 'KH386338', '2023-10-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31266429', 'NV950327', 'KH575389', '2024-07-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31862596', 'NV594273', 'KH696026', '2024-10-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31992472', 'NV717819', 'KH545858', '2024-08-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32127415', 'NV413814', 'KH585669', '2023-06-18', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32153563', 'NV454412', 'KH780705', '2024-12-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32167386', 'NV950327', 'KH977771', '2023-12-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32437694', 'NV659671', 'KH761758', '2023-01-26', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32585794', 'NV849197', 'KH529157', '2024-09-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32737725', 'NV596246', 'KH949953', '2023-11-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('33318683', 'NV732368', 'KH203563', '2024-04-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('33527312', 'NV955885', 'KH460998', '2024-09-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('33744759', 'NV890913', 'KH658936', '2023-10-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34170978', 'NV955706', 'KH941652', '2024-05-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34279066', 'NV240888', 'KH947121', '2024-05-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34913635', 'NV289904', 'KH541552', '2023-11-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34982804', 'NV325416', 'KH374822', '2023-06-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35254394', 'NV077006', 'KH419510', '2023-02-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35521126', 'NV201665', 'KH947121', '2023-09-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35690416', 'NV253335', 'KH984343', '2024-06-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35855507', 'NV856226', 'KH773285', '2023-01-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36046393', 'NV659671', 'KH591464', '2024-09-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36101432', 'NV132568', 'KH936694', '2024-02-03', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36260630', 'NV413814', 'KH814108', '2024-03-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36903170', 'NV363798', 'KH446901', '2024-10-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36911132', 'NV955706', 'KH988988', '2024-06-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37029575', 'NV925832', 'KH760944', '2024-01-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37515146', 'NV196736', 'KH860169', '2023-09-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37620251', 'NV376524', 'KH460998', '2024-12-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37992672', 'NV340941', 'KH396109', '2024-11-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('38163733', 'NV059671', 'KH557590', '2024-12-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('38240234', 'NV832790', 'KH601439', '2023-02-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('40008069', 'NV979641', 'KH032071', '2024-04-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('40402161', 'NV550817', 'KH237192', '2023-07-03', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('40851325', 'NV044506', 'KH723964', '2023-04-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('41013275', 'NV041942', 'KH558152', '2024-02-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('41288359', 'NV849707', 'KH483866', '2023-10-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('42416206', 'NV510405', 'KH541552', '2023-03-18', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('42523517', 'NV660217', 'KH535109', '2023-05-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('42635597', 'NV955706', 'KH141805', '2023-01-15', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43163666', 'NV450177', 'KH407901', '2024-11-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43618595', 'NV940794', 'KH170428', '2023-02-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43698138', 'NV787213', 'KH780705', '2023-11-11', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43851343', 'NV429712', 'KH847284', '2023-10-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44118206', 'NV594273', 'KH425172', '2024-10-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44754731', 'NV073871', 'KH121401', '2023-11-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44828717', 'NV594273', 'KH153049', '2023-12-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44981970', 'NV082912', 'KH083638', '2023-05-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('45159474', 'NV659802', 'KH460998', '2024-01-28', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('45925652', 'NV582109', 'KH344217', '2024-03-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46458379', 'NV391581', 'KH780705', '2024-07-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46548531', 'NV262355', 'KH462707', '2024-10-26', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46608208', 'NV676162', 'KH231668', '2023-02-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46631736', 'NV189822', 'KH390926', '2023-02-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46837887', 'NV732368', 'KH393702', '2024-01-30', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46870131', 'NV339957', 'KH877635', '2024-03-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47036692', 'NV079311', 'KH437596', '2023-01-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47062940', 'NV010574', 'KH056342', '2023-03-26', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47140966', 'NV568902', 'KH706729', '2023-07-15', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47304726', 'NV078937', 'KH816691', '2024-10-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47389329', 'NV711456', 'KH469917', '2024-04-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47613873', 'NV941014', 'KH677059', '2023-09-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47889887', 'NV822716', 'KH070493', '2024-03-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48215948', 'NV059671', 'KH870175', '2024-04-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48785703', 'NV790581', 'KH004422', '2024-02-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48948937', 'NV085281', 'KH710303', '2024-03-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48958287', 'NV264057', 'KH056342', '2024-11-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49092451', 'NV888660', 'KH847284', '2024-11-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49099592', 'NV888660', 'KH365036', '2024-05-03', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49159569', 'NV921688', 'KH112531', '2024-08-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49562547', 'NV447108', 'KH334932', '2023-12-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49838361', 'NV955885', 'KH004422', '2024-01-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49866923', 'NV659671', 'KH141805', '2024-06-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50135398', 'NV281921', 'KH221463', '2023-02-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50512777', 'NV955885', 'KH315582', '2024-07-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50519849', 'NV288830', 'KH285533', '2024-02-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50902262', 'NV450177', 'KH819668', '2023-01-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51190625', 'NV659671', 'KH621641', '2024-07-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51472095', 'NV955885', 'KH980984', '2023-02-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51686845', 'NV325416', 'KH697828', '2024-05-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51757291', 'NV594273', 'KH895693', '2024-08-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51991359', 'NV531991', 'KH987796', '2024-10-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52260834', 'NV264057', 'KH863030', '2023-02-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52263074', 'NV856226', 'KH757285', '2023-11-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52287025', 'NV979641', 'KH391834', '2024-11-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52546308', 'NV676162', 'KH336007', '2024-09-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53054109', 'NV928013', 'KH986650', '2023-10-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53286397', 'NV650538', 'KH362854', '2023-09-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53455827', 'NV077006', 'KH086552', '2023-12-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53558431', 'NV955988', 'KH380827', '2024-10-13', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54045234', 'NV945233', 'KH832329', '2023-11-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54309694', 'NV928013', 'KH098035', '2024-01-09', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54324904', 'NV425018', 'KH118901', '2024-09-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54496894', 'NV946657', 'KH341501', '2024-11-23', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54546886', 'NV550817', 'KH577751', '2024-03-03', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54633275', 'NV262355', 'KH541552', '2023-05-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54757028', 'NV376524', 'KH022658', '2024-08-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54869471', 'NV487204', 'KH872145', '2023-10-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55064095', 'NV408057', 'KH376951', '2024-04-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55367392', 'NV019077', 'KH285533', '2023-11-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55423765', 'NV444738', 'KH339380', '2023-02-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55575314', 'NV660217', 'KH320177', '2023-02-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55603420', 'NV193469', 'KH651808', '2024-08-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55881706', 'NV264057', 'KH084753', '2024-09-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56232616', 'NV568902', 'KH773307', '2023-04-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56410821', 'NV164312', 'KH236596', '2023-07-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56737208', 'NV789781', 'KH293180', '2023-03-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56776600', 'NV890913', 'KH216038', '2024-03-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56886025', 'NV582109', 'KH529157', '2024-01-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57139807', 'NV240973', 'KH172746', '2023-11-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57280817', 'NV901134', 'KH564833', '2023-03-31', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57375637', 'NV941014', 'KH128339', '2024-10-22', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57615741', 'NV262355', 'KH582692', '2023-12-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57618852', 'NV158614', 'KH842523', '2023-01-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('58104633', 'NV383849', 'KH384345', '2023-06-25', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('58195887', 'NV477238', 'KH492275', '2024-02-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('58613381', 'NV940794', 'KH910997', '2023-05-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59091091', 'NV790581', 'KH478576', '2024-06-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59201145', 'NV158614', 'KH621641', '2024-09-13', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59428683', 'NV047107', 'KH796829', '2023-07-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59808596', 'NV592137', 'KH378830', '2023-02-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59829567', 'NV510405', 'KH562909', '2023-07-04', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59875197', 'NV060507', 'KH029547', '2023-04-23', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59991562', 'NV964113', 'KH900537', '2024-05-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60051135', 'NV574049', 'KH283594', '2024-07-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60051996', 'NV413814', 'KH407901', '2023-11-17', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60606285', 'NV439113', 'KH929292', '2023-06-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60680740', 'NV579268', 'KH234451', '2024-04-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60993800', 'NV383849', 'KH386338', '2024-04-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61146430', 'NV481500', 'KH153049', '2024-05-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61300575', 'NV835274', 'KH545916', '2024-06-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61304023', 'NV928013', 'KH341501', '2023-09-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61488272', 'NV010574', 'KH382525', '2024-09-14', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61699687', 'NV303957', 'KH070493', '2024-08-18', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61914355', 'NV193026', 'KH621641', '2023-09-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62143514', 'NV735464', 'KH297971', '2023-08-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62493694', 'NV240888', 'KH819668', '2024-05-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62761266', 'NV439113', 'KH059888', '2024-01-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62764221', 'NV487204', 'KH884843', '2023-08-18', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62883796', 'NV849707', 'KH098035', '2024-11-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63131447', 'NV277291', 'KH375794', '2024-04-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63510743', 'NV925832', 'KH135574', '2024-05-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63531457', 'NV573727', 'KH128339', '2023-01-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63578463', 'NV510405', 'KH473189', '2023-06-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63623076', 'NV281921', 'KH384345', '2023-03-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63842193', 'NV240973', 'KH935820', '2024-09-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64064793', 'NV901134', 'KH285098', '2024-09-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64079428', 'NV790581', 'KH666660', '2023-11-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64146299', 'NV025466', 'KH112531', '2023-11-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64765966', 'NV676162', 'KH079281', '2023-08-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64851539', 'NV596246', 'KH842523', '2023-06-24', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('65491815', 'NV092108', 'KH716623', '2023-10-29', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('65505218', 'NV901134', 'KH494290', '2023-05-09', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('65712213', 'NV787213', 'KH682141', '2023-06-20', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66102208', 'NV634749', 'KH297971', '2023-01-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66188574', 'NV890913', 'KH740368', '2024-01-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66356738', 'NV012052', 'KH920085', '2024-01-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66427363', 'NV639320', 'KH949953', '2024-05-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66585896', 'NV201665', 'KH820633', '2023-01-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67125189', 'NV271794', 'KH677059', '2024-03-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67253718', 'NV164312', 'KH958880', '2024-06-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67273520', 'NV297438', 'KH374822', '2023-01-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67415180', 'NV659671', 'KH575389', '2024-04-11', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67493116', 'NV367893', 'KH518463', '2023-11-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67696349', 'NV659802', 'KH460998', '2024-07-28', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67882602', 'NV223401', 'KH006633', '2024-05-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67888864', 'NV574049', 'KH599858', '2024-09-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67999316', 'NV480270', 'KH526686', '2024-07-23', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68141332', 'NV660753', 'KH149810', '2023-10-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68212839', 'NV660217', 'KH409572', '2024-03-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68488171', 'NV521642', 'KH132801', '2024-09-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68554816', 'NV894914', 'KH084013', '2023-05-13', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68593258', 'NV240973', 'KH876167', '2024-05-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68681176', 'NV060507', 'KH237493', '2024-03-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68807531', 'NV619036', 'KH713210', '2023-06-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68956633', 'NV790581', 'KH544891', '2024-01-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69073457', 'NV955988', 'KH621641', '2024-02-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69100259', 'NV010574', 'KH120054', '2024-01-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69194990', 'NV950327', 'KH442934', '2023-04-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69309970', 'NV122335', 'KH350452', '2023-09-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69808473', 'NV676162', 'KH145038', '2024-02-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('70272289', 'NV303957', 'KH172746', '2023-12-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('70328718', 'NV297438', 'KH760944', '2024-08-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('70377200', 'NV850462', 'KH204348', '2024-09-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71210252', 'NV408057', 'KH592532', '2023-08-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71368887', 'NV303894', 'KH384345', '2023-08-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71801009', 'NV992229', 'KH558718', '2023-03-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71909829', 'NV850038', 'KH236596', '2023-09-18', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72205127', 'NV928013', 'KH017103', '2024-09-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72230777', 'NV524840', 'KH147192', '2024-03-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72294479', 'NV888660', 'KH066621', '2023-01-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72418778', 'NV619036', 'KH714662', '2024-12-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('73758764', 'NV941879', 'KH977771', '2023-03-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74460311', 'NV178173', 'KH306439', '2023-05-23', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74686265', 'NV480270', 'KH056342', '2023-09-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74867866', 'NV429712', 'KH965543', '2024-04-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74869186', 'NV105604', 'KH958880', '2024-05-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74946433', 'NV531991', 'KH084013', '2024-11-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75645929', 'NV992229', 'KH772577', '2024-09-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75689282', 'NV650538', 'KH914683', '2023-03-09', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75750998', 'NV160815', 'KH227910', '2024-06-21', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75953436', 'NV161099', 'KH227910', '2023-11-14', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75960033', 'NV711456', 'KH949953', '2024-07-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('77335529', 'NV057942', 'KH791545', '2023-11-21', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('77379402', 'NV339957', 'KH694938', '2024-03-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('77555844', 'NV620763', 'KH791759', '2024-02-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78412233', 'NV650538', 'KH522691', '2024-07-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78518151', 'NV193469', 'KH796829', '2023-07-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78864629', 'NV158614', 'KH460521', '2024-01-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78920552', 'NV453523', 'KH291338', '2024-05-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78967747', 'NV797940', 'KH098035', '2023-03-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79177322', 'NV376524', 'KH987796', '2024-09-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79396331', 'NV521642', 'KH437409', '2024-10-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79652274', 'NV303199', 'KH549396', '2023-11-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79746616', 'NV711456', 'KH562909', '2024-03-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('80506782', 'NV480270', 'KH870175', '2024-03-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('80935436', 'NV012052', 'KH119243', '2024-07-30', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('80962217', 'NV164312', 'KH483866', '2023-09-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81015092', 'NV964113', 'KH832329', '2023-12-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81073581', 'NV592137', 'KH157277', '2024-06-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81231428', 'NV496066', 'KH154664', '2024-03-30', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81314976', 'NV085281', 'KH716623', '2023-07-31', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81477356', 'NV392010', 'KH099791', '2023-12-09', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81674784', 'NV888660', 'KH128603', '2024-07-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81873049', 'NV979641', 'KH380827', '2023-12-08', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81958720', 'NV343692', 'KH087105', '2024-09-02', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82122385', 'NV875495', 'KH958880', '2023-11-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82163171', 'NV941014', 'KH714295', '2023-08-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82696945', 'NV415824', 'KH453142', '2023-11-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82704385', 'NV738399', 'KH876167', '2024-04-23', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82717794', 'NV391581', 'KH057137', '2023-10-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83042107', 'NV675961', 'KH545858', '2023-06-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83054764', 'NV180911', 'KH355802', '2024-06-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83191185', 'NV077006', 'KH706729', '2023-03-03', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83298123', 'NV480270', 'KH919695', '2023-12-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83379534', 'NV303199', 'KH441817', '2023-01-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83380519', 'NV645678', 'KH179505', '2024-06-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83413062', 'NV025466', 'KH154664', '2023-02-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83447776', 'NV392010', 'KH362680', '2023-11-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83481842', 'NV077006', 'KH355802', '2023-01-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83960238', 'NV890100', 'KH710303', '2024-08-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('84424932', 'NV596246', 'KH621641', '2024-03-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('84707385', 'NV717819', 'KH013100', '2024-12-22', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85337194', 'NV079311', 'KH558152', '2024-04-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85482795', 'NV850038', 'KH407901', '2023-07-02', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85770297', 'NV433504', 'KH975326', '2024-03-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85857885', 'NV925832', 'KH119243', '2023-09-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85967836', 'NV905823', 'KH757285', '2024-02-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('86161532', 'NV955885', 'KH147192', '2024-04-14', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('86182227', 'NV789781', 'KH391834', '2024-12-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87076460', 'NV531991', 'KH823647', '2023-08-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87257749', 'NV264057', 'KH895693', '2023-06-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87498485', 'NV098182', 'KH522691', '2024-12-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87615837', 'NV408057', 'KH658936', '2024-09-26', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87766736', 'NV950327', 'KH903096', '2024-09-27', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87835257', 'NV894914', 'KH522691', '2023-09-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87898902', 'NV539311', 'KH700174', '2023-10-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88064742', 'NV440528', 'KH683530', '2024-09-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88087511', 'NV496066', 'KH740368', '2024-12-11', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88261127', 'NV440528', 'KH529157', '2024-12-15', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88346856', 'NV797940', 'KH008583', '2024-04-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88660704', 'NV164312', 'KH919695', '2024-09-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88707289', 'NV132568', 'KH099791', '2024-06-11', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88828477', 'NV339957', 'KH158297', '2023-09-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88853460', 'NV441589', 'KH018367', '2023-05-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88855917', 'NV160815', 'KH396109', '2024-08-14', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88880729', 'NV281921', 'KH773285', '2024-09-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89096598', 'NV940794', 'KH790357', '2023-10-06', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89301934', 'NV059671', 'KH376951', '2024-02-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89445564', 'NV383849', 'KH271569', '2023-11-09', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89461258', 'NV303957', 'KH714662', '2023-01-19', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90079336', 'NV440528', 'KH786340', '2024-10-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90317087', 'NV057942', 'KH545858', '2023-07-30', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90351583', 'NV367893', 'KH563902', '2023-11-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90431741', 'NV850038', 'KH375073', '2023-10-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90649500', 'NV132568', 'KH088786', '2023-06-20', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90787904', 'NV955885', 'KH529157', '2024-11-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90831040', 'NV496066', 'KH666660', '2024-04-22', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90988734', 'NV650538', 'KH494290', '2023-02-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90994110', 'NV201665', 'KH096988', '2023-09-16', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90999927', 'NV161099', 'KH386338', '2023-10-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91023762', 'NV098182', 'KH817290', '2023-12-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91144158', 'NV835274', 'KH375317', '2023-02-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91236619', 'NV433504', 'KH044397', '2023-12-26', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91249247', 'NV057942', 'KH773285', '2023-02-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91447270', 'NV921688', 'KH006633', '2023-03-23', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91617761', 'NV619036', 'KH748649', '2024-07-17', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91925109', 'NV496066', 'KH128603', '2023-05-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91947888', 'NV573727', 'KH170428', '2023-11-10', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92033882', 'NV077006', 'KH575389', '2024-07-11', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92039250', 'NV325416', 'KH170428', '2023-05-23', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92077884', 'NV659802', 'KH008583', '2023-04-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92391942', 'NV639320', 'KH462707', '2024-06-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92488546', 'NV425018', 'KH481886', '2023-06-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92612348', 'NV454412', 'KH672845', '2024-04-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92827922', 'NV594273', 'KH027997', '2024-11-04', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92951368', 'NV308774', 'KH099823', '2024-06-08', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93399362', 'NV242498', 'KH939840', '2024-04-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93543773', 'NV941014', 'KH362854', '2024-08-07', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93795457', 'NV510405', 'KH535109', '2024-02-12', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93961964', 'NV592137', 'KH039286', '2024-05-13', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94198005', 'NV223401', 'KH473189', '2024-02-07', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94386793', 'NV060507', 'KH496697', '2023-10-15', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94398535', 'NV477238', 'KH830363', '2024-10-10', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94687846', 'NV439113', 'KH714662', '2024-02-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94830505', 'NV955885', 'KH518463', '2024-11-05', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('95517222', 'NV888660', 'KH131158', '2024-04-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('95975109', 'NV079311', 'KH697088', '2024-11-12', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96037462', 'NV477238', 'KH707432', '2024-12-15', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96076090', 'NV367893', 'KH283594', '2023-05-31', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96240176', 'NV178173', 'KH669308', '2023-06-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96311209', 'NV481500', 'KH782287', '2023-06-21', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96604089', 'NV044506', 'KH013100', '2024-06-16', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96675854', 'NV454412', 'KH491026', '2023-12-24', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97495281', 'NV059671', 'KH707432', '2023-08-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97627792', 'NV596246', 'KH153049', '2023-12-05', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97655772', 'NV518097', 'KH518463', '2023-03-14', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97679853', 'NV659802', 'KH709442', '2023-09-29', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97772063', 'NV288830', 'KH860169', '2023-04-01', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98257461', 'NV047107', 'KH370303', '2024-01-23', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98332302', 'NV550817', 'KH414310', '2023-09-03', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98448395', 'NV303894', 'KH536661', '2023-08-25', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98845092', 'NV835274', 'KH380827', '2024-10-06', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99149331', 'NV832790', 'KH291338', '2024-03-28', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99168318', 'NV955988', 'KH374203', '2024-10-27', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99454089', 'NV343692', 'KH536661', '2023-12-19', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99551548', 'NV044506', 'KH904366', '2024-02-22', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99579686', 'NV964113', 'KH018367', '2024-06-29', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99619728', 'NV240973', 'KH302564', '2024-01-25', '0');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99675600', 'NV281921', 'KH094387', '2024-06-13', '1');
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99715059', 'NV660217', 'KH121401', '2023-03-23', '0');

-- Thêm dữ liệu cho bảng VE
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AFII2076', 'W', 'XK 113  ', '61914355', '58', '1712.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('APPT0275', 'J', 'UD 378  ', '20161572', '49', '313.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ARAX0794', 'J', 'KB 938  ', '69100259', '50', '3724.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ATQN5183', 'Y', 'LU 202  ', '46458379', '144', '2518.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AUYV4305', 'Y', 'EA 805  ', '17443686', '41', '2862.36');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BBHQ4708', 'W', 'CM 255  ', '53558431', '136', '814.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BEQO8574', 'Y', 'XF 402  ', '20049535', '35', '3987.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BFDM8108', 'J', 'EA 714  ', '57375637', '25', '1698.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BGGN6290', 'J', 'ST 147  ', '16466095', '179', '1709.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BHGG0493', 'J', 'DF 740  ', '15076148', '35', '1039.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BOCG2438', 'J', 'QF 607  ', '72294479', '35', '2179.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BSLN2363', 'W', 'LV 508  ', '23187054', '61', '3469.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BVWG8515', 'Y', 'FT 215  ', '62143514', '19', '3496.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CFVQ5233', 'Y', 'GW 845  ', '04356983', '105', '1129.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CGHN8897', 'J', 'QF 239  ', '90994110', '77', '4321.7');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CGNL5835', 'Y', 'EN 334  ', '18719517', '95', '3634.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CZDK8340', 'W', 'CD 263  ', '87257749', '183', '2819.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CZIE4167', 'W', 'VB 795  ', '13528822', '97', '152.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CZPB0104', 'W', 'CU 286  ', '17542571', '38', '2123.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DEFR7519', 'W', 'QF 239  ', '38163733', '47', '291.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DIDR5238', 'J', 'IF 068  ', '28318408', '116', '2028.52');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DPCF0450', 'J', 'DY 653  ', '15076148', '104', '1018.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DPND1464', 'Y', 'FZ 441  ', '64851539', '114', '3760.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DSGB9614', 'J', 'QS 839  ', '13933332', '54', '737.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DYMV2903', 'W', 'KH 340  ', '61300575', '117', '1066.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DYWG1989', 'J', 'YF 362  ', '97627792', '163', '4898.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EFVP1493', 'W', 'YL 505  ', '65491815', '183', '2682.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EJOE6011', 'J', 'MG 930  ', '57618852', '21', '447.1');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EMUR0037', 'J', 'WE 064  ', '85967836', '86', '4771.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EQUX0788', 'W', 'MU 795  ', '25142090', '60', '1676.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ERUX3763', 'Y', 'MP 271  ', '16531754', '61', '1373.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ESAW5028', 'Y', 'ML 770  ', '71368887', '88', '3241.4');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ETRB5124', 'J', 'FT 190  ', '65712213', '77', '3955.5');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EVVB9130', 'Y', 'DY 653  ', '81477356', '26', '2656.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EZWJ4494', 'W', 'VI 246  ', '77335529', '72', '3923.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FAEM1922', 'Y', 'CM 255  ', '15250752', '139', '2843.8');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FDSE8499', 'Y', 'UF 966  ', '10174845', '51', '849.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FFDK0488', 'Y', 'WI 057  ', '57280817', '96', '4991.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FIUU1638', 'W', 'CD 263  ', '59808596', '148', '4532.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FNCA3317', 'W', 'VV 600  ', '25535597', '57', '3777.3');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FPUY1183', 'W', 'CD 263  ', '81674784', '204', '3729');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FTMX3433', 'J', 'QZ 396  ', '78518151', '12', '4319.03');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FWAS4054', 'J', 'ZP 863  ', '83191185', '9', '3926.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GAMA3279', 'Y', 'JW 088  ', '17387584', '101', '1920.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GAQI9253', 'W', 'NS 674  ', '56886025', '64', '4818.5');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GDGZ9012', 'W', 'CS 257  ', '59829567', '94', '3791.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GHIZ1073', 'J', 'VH 352  ', '92039250', '13', '3662.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GIEH2324', 'W', 'RS 632  ', '06062676', '191', '4813.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GJRT0986', 'J', 'FK 002  ', '75750998', '96', '351.4');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GSLJ1508', 'J', 'FM 573  ', '18169248', '72', '4308.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GXHO7096', 'J', 'FT 589  ', '81314976', '207', '2582.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HDVS5614', 'J', 'FZ 441  ', '15902113', '85', '912.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HENT9756', 'Y', 'VV 600  ', '81958720', '107', '3126.78');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HFAK1435', 'Y', 'FT 215  ', '01373041', '113', '1612.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HOJD9864', 'Y', 'OL 737  ', '35254394', '31', '1490.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HUIK5498', 'W', 'ZG 279  ', '30797850', '42', '1637.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HWNW2366', 'Y', 'YF 362  ', '68554816', '86', '799.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IBBD8808', 'W', 'FM 573  ', '42416206', '116', '3090.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ICHY1398', 'W', 'ZJ 357  ', '00130557', '12', '4466.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IDFQ5422', 'W', 'YF 362  ', '15324566', '87', '1431.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IFES6017', 'W', 'UF 966  ', '59091091', '116', '1185.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IFRC3577', 'Y', 'YL 505  ', '26815410', '192', '1655.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IHCY0659', 'J', 'ZP 863  ', '72230777', '134', '2622.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IHKE8874', 'Y', 'ML 770  ', '35254394', '22', '2349.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IOPQ2181', 'W', 'QS 839  ', '88346856', '30', '1644.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IPKV9339', 'W', 'CC 450  ', '17815063', '18', '4604.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IWCB2074', 'Y', 'IA 834  ', '93543773', '78', '1272.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IWVH2926', 'W', 'QH 964  ', '29358314', '28', '4314.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IYVV1287', 'J', 'KG 314  ', '15076148', '24', '3247.65');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JBTY7093', 'Y', 'DY 653  ', '36260630', '157', '2845.7');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JDIN4739', 'J', 'RG 468  ', '59991562', '72', '3476.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JEET7090', 'W', 'CM 255  ', '91144158', '155', '3663.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JGEO5540', 'Y', 'IH 336  ', '93543773', '100', '1508.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JGZK4351', 'Y', 'MG 930  ', '97627792', '138', '4077.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JOPK9782', 'W', 'OL 737  ', '01293073', '6', '3216.7');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JOYN8985', 'J', 'OL 737  ', '05146450', '35', '1678.2');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JQNI9850', 'Y', 'YS 207  ', '99675600', '111', '2227.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JSTM6767', 'W', 'ZE 184  ', '04679087', '80', '1069.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JSWB4716', 'J', 'FT 190  ', '15308723', '60', '3120.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JVBP7473', 'Y', 'LX 199  ', '26677987', '167', '4097.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JXAD9851', 'Y', 'UL 806  ', '22234337', '94', '1135.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JYZN0747', 'J', 'DY 653  ', '90317087', '73', '4314.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KCDG3850', 'J', 'ZP 863  ', '85770297', '130', '4424.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KEQF9858', 'Y', 'RS 632  ', '55367392', '111', '4106.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KRDD9671', 'W', 'NS 674  ', '20391629', '94', '2964.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KTAB9617', 'J', 'DT 673  ', '18282997', '127', '4414.13');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KUDK8170', 'J', 'AG 553  ', '26010133', '117', '2238.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KURU3249', 'Y', 'PI 359  ', '68681176', '22', '1845.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KVCP8055', 'J', 'LU 202  ', '94386793', '114', '3647.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KWNA3418', 'W', 'VB 795  ', '86182227', '45', '2190.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LBKO6853', 'Y', 'EB 303  ', '41013275', '14', '648.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LDIF4043', 'J', 'MP 271  ', '58104633', '19', '4200');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LHWP2389', 'J', 'JR 712  ', '59201145', '92', '4858.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LQUU6771', 'W', 'QH 964  ', '67696349', '17', '4654.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MAQZ0225', 'J', 'NS 674  ', '27332016', '116', '3644.41');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MHJI3693', 'W', 'GP 148  ', '81873049', '201', '280.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MLTW2095', 'Y', 'FT 589  ', '73758764', '87', '2741.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MOBY8103', 'J', 'RG 468  ', '09860333', '56', '698.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MOPE4674', 'W', 'ZE 184  ', '05949964', '60', '247.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MPZV6497', 'W', 'MG 930  ', '73758764', '145', '165.1');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NBIL7407', 'J', 'EB 303  ', '01616005', '186', '705.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NCHV1466', 'W', 'TV 344  ', '34982804', '150', '252.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NDLK8634', 'Y', 'NS 674  ', '84707385', '60', '1684.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NDSZ2968', 'W', 'FT 215  ', '34913635', '129', '4464.99');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NFLF0452', 'J', 'VB 795  ', '64851539', '167', '2159.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NGQG2683', 'Y', 'VH 352  ', '21047967', '145', '4190.39');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NHGO4044', 'J', 'VV 600  ', '17443686', '33', '3433.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NHIN1385', 'J', 'FQ 490  ', '19014083', '87', '1137.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NKFB2911', 'Y', 'RG 468  ', '31862596', '74', '3226.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NYBG5459', 'W', 'FZ 441  ', '99168318', '172', '4343.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NZCG8624', 'W', 'RG 468  ', '16531754', '140', '2438.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ODWN6384', 'W', 'UD 378  ', '99579686', '111', '3603.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OGZH2127', 'J', 'SE 323  ', '30347601', '178', '3148.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OIND4278', 'W', 'IA 834  ', '32167386', '92', '4758.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OJTT1300', 'W', 'DF 740  ', '62143514', '31', '3268.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OKBI5472', 'Y', 'FZ 441  ', '89461258', '95', '392.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OKUW7185', 'Y', 'ST 147  ', '40402161', '29', '3996.97');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OLWF8011', 'J', 'CC 450  ', '17815063', '95', '2442.7');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OOFS2374', 'J', 'QS 839  ', '14069840', '131', '3334.49');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OSTF4923', 'Y', 'IJ 564  ', '26010133', '28', '253.69');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OTQN7018', 'W', 'NS 674  ', '89096598', '168', '1297.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OUUJ5366', 'Y', 'VB 795  ', '61699687', '200', '4512.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PCLP7523', 'W', 'WW 742  ', '20502716', '37', '1666.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PDQO8367', 'Y', 'QF 239  ', '18226382', '121', '3934.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PHNH5232', 'J', 'IG 452  ', '98448395', '88', '816.66');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PJIW1330', 'W', 'RS 632  ', '60606285', '109', '4001.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PKKH5631', 'J', 'EL 557  ', '29440514', '134', '762.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PNXY3172', 'J', 'RI 271  ', '91947888', '103', '3381.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PYCR9678', 'Y', 'EB 303  ', '56410821', '74', '794.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PYKJ9301', 'J', 'LU 202  ', '21163258', '139', '3814.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PZMF6937', 'W', 'FK 002  ', '40402161', '165', '4775.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QEUS4216', 'Y', 'UF 966  ', '49099592', '71', '1757.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QGDI6938', 'J', 'JZ 483  ', '18169248', '143', '1749.37');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QRIH8897', 'F', 'CR 563  ', '29967804', '1', '4415.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QVNC8605', 'Y', 'JR 712  ', '06062676', '81', '993.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QXCV2450', 'J', 'UF 966  ', '17542571', '90', '598.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RDWR9184', 'J', 'ZJ 357  ', '28151554', '26', '1135.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RFAU4078', 'W', 'ML 770  ', '91236619', '60', '783.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RNLA6356', 'J', 'IH 336  ', '64851539', '85', '3536.81');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RTFB9770', 'Y', 'IA 834  ', '05502162', '50', '4304.1');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RWNZ2793', 'J', 'BL 389  ', '92033882', '93', '2361.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RXCZ8916', 'W', 'YF 362  ', '05949964', '26', '534.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RXKS5228', 'Y', 'FW 269  ', '16752375', '58', '4268.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SAET5332', 'Y', 'TV 344  ', '62764221', '30', '2835.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SEND6162', 'J', 'IH 336  ', '36260630', '14', '1740.5');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SETU1366', 'Y', 'VH 352  ', '99579686', '125', '3022.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SHEI9072', 'W', 'YF 362  ', '60051996', '27', '1853.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SJBF4273', 'W', 'MQ 793  ', '75953436', '98', '4812.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SJXV4990', 'W', 'AG 553  ', '32127415', '102', '2776.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SREK4951', 'Y', 'MG 930  ', '48958287', '32', '4203.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SUVE3545', 'Y', 'OC 854  ', '61488272', '35', '2155.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SYIL1038', 'W', 'LX 199  ', '44828717', '169', '4939.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SYOC6448', 'Y', 'ZP 863  ', '86161532', '87', '2640.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SZZU2924', 'J', 'NR 260  ', '27030355', '129', '120.2');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TEHZ8547', 'Y', 'ZE 184  ', '70272289', '115', '2794.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('THSY3158', 'J', 'IJ 564  ', '16346188', '81', '799.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TIOO9017', 'W', 'IG 452  ', '23273614', '59', '4364.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TLQC8733', 'Y', 'PE 344  ', '88828477', '157', '4343.67');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TNNV2959', 'W', 'RX 159  ', '74460311', '173', '1729.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TPGT6871', 'J', 'UD 378  ', '97655772', '161', '995.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TXIR0439', 'W', 'CD 263  ', '41013275', '116', '4653.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UEBZ0861', 'J', 'PE 344  ', '47613873', '162', '3883.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UEIS9927', 'W', 'PE 344  ', '95517222', '56', '2622.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UIPA9396', 'W', 'OC 854  ', '36101432', '24', '4390.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UJHY2413', 'W', 'FQ 490  ', '68593258', '128', '3767.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UOAR4938', 'W', 'DF 740  ', '99551548', '142', '280.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UPDG1010', 'W', 'LU 202  ', '84707385', '50', '4077.65');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UPEV9886', 'Y', 'LX 199  ', '75689282', '116', '1870.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UPZZ7778', 'Y', 'VI 246  ', '68212839', '133', '1886.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UXIQ5472', 'Y', 'OJ 008  ', '81958720', '79', '3903.5');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VCNS0117', 'J', 'RS 632  ', '88707289', '190', '592.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VGMB6736', 'Y', 'JZ 483  ', '91447270', '103', '1876.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VHZT6830', 'Y', 'VI 246  ', '88346856', '56', '92.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VQBH5528', 'W', 'XF 402  ', '21163258', '57', '4639.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VSRV4560', 'J', 'NE 668  ', '85337194', '150', '2643.78');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VTLM0661', 'W', 'GW 845  ', '45159474', '109', '1539.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VUDP9654', 'Y', 'AT 362  ', '06058572', '68', '4862.41');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VUNK6195', 'Y', 'MU 795  ', '93795457', '56', '48.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VWKK8961', 'W', 'GP 148  ', '55064095', '185', '2227.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WKWF0122', 'Y', 'PI 359  ', '55423765', '150', '2561.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WLLE2522', 'W', 'ST 147  ', '18226382', '99', '541.1');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WOFX5857', 'J', 'CD 263  ', '58613381', '186', '4067.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WSLU5784', 'J', 'FW 269  ', '07199807', '20', '627.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WTVD8934', 'J', 'ZH 266  ', '19249690', '78', '4382.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WXJX1143', 'Y', 'WI 057  ', '11057658', '105', '4091.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WXUG4967', 'Y', 'LX 199  ', '90431741', '77', '3078.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WYCX2106', 'Y', 'GE 692  ', '90431741', '162', '1483.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XBVM4523', 'Y', 'FT 589  ', '00130557', '44', '4533.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XBYD4252', 'W', 'CU 286  ', '59991562', '170', '3033.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XDXW1786', 'Y', 'ZJ 357  ', '17443686', '96', '1398.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XEJX8642', 'W', 'CM 255  ', '20502716', '142', '4884.3');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XKKS0210', 'Y', 'FT 589  ', '17443686', '109', '1315.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XNJY5580', 'J', 'GX 201  ', '28702515', '75', '1400.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XSXU9673', 'W', 'RS 632  ', '58613381', '160', '4827.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XZDS4068', 'W', 'EI 901  ', '62143514', '37', '1557.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YCHD0371', 'W', 'LU 202  ', '19453685', '55', '2807.4');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YDIP8481', 'W', 'ZJ 357  ', '81314976', '134', '4787.6');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YFHA2740', 'J', 'DF 740  ', '89445564', '96', '4024.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YGIU9637', 'Y', 'PI 359  ', '45159474', '190', '1735.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YLXA1634', 'Y', 'CR 563  ', '98257461', '73', '1731.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YMTP9561', 'W', 'UF 966  ', '46837887', '125', '1625');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YMWH0514', 'W', 'TV 344  ', '80962217', '109', '4881.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YOSK0453', 'Y', 'AN 989  ', '05396256', '109', '4209.1');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YQQT1718', 'W', 'NR 260  ', '11057658', '26', '3036.85');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YUFQ6675', 'J', 'RI 271  ', '16346188', '41', '2853.04');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YYCY4611', 'W', 'GV 164  ', '17056136', '135', '2732.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YYJK5389', 'W', 'VV 600  ', '97627792', '115', '577.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZATM9996', 'W', 'UD 378  ', '48958287', '118', '458.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZHBJ8831', 'W', 'GP 148  ', '80935436', '81', '3390.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZJQH9905', 'Y', 'VP 100  ', '54546886', '114', '1476.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZMLB0819', 'J', 'AN 989  ', '15095037', '169', '992.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZOVH3338', 'J', 'MU 795  ', '54633275', '140', '4178.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZQAC5978', 'W', 'QF 607  ', '37029575', '103', '3968.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZVRQ7945', 'W', 'QZ 396  ', '46458379', '20', '3188.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZWDG6199', 'W', 'CM 255  ', '58104633', '37', '3641.29');

-- PHÂN QUYỀN (ROLE & USER)
-- Tạo role
CREATE ROLE 'admin_role';
CREATE ROLE 'nhanvien_role';
CREATE ROLE 'khachhang_role';

-- Tạo user
CREATE USER 'admin_user'@'%' IDENTIFIED BY 'yourAdminPassword';
CREATE USER 'nhanvien_user'@'%' IDENTIFIED BY 'yourNhanVienPassword';
CREATE USER 'khachhang_user'@'%' IDENTIFIED BY 'yourKhachHangPassword';

-- Gán role cho user
GRANT 'admin_role' TO 'admin_user'@'%';
GRANT 'nhanvien_role' TO 'nhanvien_user'@'%';
GRANT 'khachhang_role' TO 'khachhang_user'@'%';

-- Cấp quyền quản lý toàn bộ database cho admin
GRANT ALL PRIVILEGES ON QUANLYCHUYENBAY.* TO 'admin_role';

-- Cấp quyền thao tác trên bảng cho nhân viên
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.CHUYENBAY TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.HOADON TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.VE TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.KHACHHANG TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.SANBAY TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.TUYENBAY TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.NHANVIEN TO 'nhanvien_role';
GRANT SELECT, INSERT, UPDATE, DELETE ON QUANLYCHUYENBAY.MAYBAY TO 'nhanvien_role';

-- Cấp quyền xem các bảng cho khách hàng
GRANT SELECT ON QUANLYCHUYENBAY.CHUYENBAY TO 'khachhang_role';
GRANT SELECT ON QUANLYCHUYENBAY.VE TO 'khachhang_role';
GRANT SELECT ON QUANLYCHUYENBAY.HOADON TO 'khachhang_role';
GRANT SELECT ON QUANLYCHUYENBAY.KHACHHANG TO 'khachhang_role';

-- Cấp quyền thực thi function cho nhân viên
GRANT EXECUTE ON FUNCTION QUANLYCHUYENBAY.FUNC_DEM_SLKHDK_THEOTHANG TO 'nhanvien_role';
GRANT EXECUTE ON FUNCTION QUANLYCHUYENBAY.FUNC_DEM_SLCB_THEOTHANG TO 'nhanvien_role';
GRANT EXECUTE ON FUNCTION QUANLYCHUYENBAY.FUNC_DOANHTHU TO 'nhanvien_role';

-- Cấp quyền thực thi procedure cho nhân viên
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_KhachHang TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_NhanVien TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_HoaDon_NhanVien_DaTao TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_HoaDon_KhachHang_DaThanhToan TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_ChuyenBay_TheoNgay TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_ChuyenBay TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_Ve_Theo_MACB TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_ThemMoi_NhanVien TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_ThemMoi_ChuyenBay TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_ThemMoi_KhachHang TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_ThemMoi_Ve TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_ThemMoi_HoaDon TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_TongTienDaMua TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_CapNhat_GiaVe TO 'nhanvien_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_TIM_CHUYENBAY TO 'nhanvien_role';

-- Cấp quyền thực thi procedure cho khách hàng
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_ChuyenBay TO 'khachhang_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_HoaDon_KhachHang_DaThanhToan TO 'khachhang_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_Ve_Theo_MACB TO 'khachhang_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_ChuyenBay_TheoNgay TO 'khachhang_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_TongTienDaMua TO 'khachhang_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_DanhSach_KhachHang TO 'khachhang_role';
GRANT EXECUTE ON PROCEDURE QUANLYCHUYENBAY.PRC_TIM_CHUYENBAY TO 'khachhang_role';

FLUSH PRIVILEGES;

-- VIEW
-- View để ẩn mật khẩu cho nhân viên
CREATE VIEW NHANVIEN_VIEW AS
SELECT MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, NGAYTAOTK
FROM NHANVIEN;

REVOKE SELECT ON QUANLYCHUYENBAY.NHANVIEN FROM nhanvien_role;
GRANT SELECT ON QUANLYCHUYENBAY.NHANVIEN_VIEW TO nhanvien_role;

-- View để ẩn mật khẩu cho khách hàng 
CREATE VIEW KHACHHANG_VIEW AS
SELECT MAKH, TENKH, GIOITINH, NGAYSINH, QUOCTICH, SODT, EMAIL, DIACHI, NGAYTAOTK
FROM KHACHHANG;

REVOKE SELECT ON QUANLYCHUYENBAY.KHACHHANG FROM nhanvien_role;
GRANT SELECT ON QUANLYCHUYENBAY.KHACHHANG_VIEW TO nhanvien_role;

-- View để xem chi tiết chuyến bay
CREATE VIEW THONGTIN_CHUYENBAY_VIEW AS
SELECT CB.MACB, NGAYKHOIHANH, GIOKHOIHANH, GIOHACANH, GIAVE, TENHANGVE
FROM CHUYENBAY CB JOIN VE ON CB.MACB = VE.MACB 
	JOIN HANGVE HV ON VE.MAHV = HV.MAHV
ORDER BY CB.MACB;
	
-- View để xem tổng tiền mua hàng của khách hàng
CREATE VIEW TONGTIEN_KHACHHANG_VIEW AS
SELECT KH.MAKH, TENKH, COALESCE(SUM(HD.THANHTIEN),0) AS TONGTIEN
FROM KHACHHANG KH LEFT JOIN HOADON HD ON KH.MAKH = HD.MAKH
WHERE TINHTRANG = 1 
GROUP BY KH.MAKH
ORDER BY KH.MAKH;

-- View để xem hóa đơn chưa thanh toán
CREATE VIEW HOADON_CHUATHANHTOAN AS
SELECT MAHD, MANV, MAKH, NGAYLAP
FROM HOADON
WHERE TINHTRANG = 0;

-- View để xem hóa đơn đã thanh toán
CREATE VIEW HOADON_DATHANHTOAN AS
SELECT MAHD, MANV, MAKH, NGAYLAP
FROM HOADON 
WHERE TINHTRANG = 1;
