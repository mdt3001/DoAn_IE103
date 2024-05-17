CREATE DATABASE QUANLYCHUYENBAY;
GO

USE QUANLYCHUYENBAY;
GO

CREATE TABLE MAYBAY (
    MAMB CHAR(8) PRIMARY KEY,
    TENMAYBAY NVARCHAR(40) NOT NULL,
    HANGSANXUAT NVARCHAR(50) NOT NULL,
    SOGHETHUONG INT NOT NULL,
    SOGHEVIP INT NOT NULL
);
GO

CREATE TABLE SANBAY (
    MASB CHAR(3) PRIMARY KEY,
    TENSB NVARCHAR(40) NOT NULL,
	DIADIEM NVARCHAR(40) NOT NULL
);
GO

CREATE TABLE TUYENBAY (
    MATB CHAR(8) PRIMARY KEY,
    MASBDI CHAR(3) FOREIGN KEY REFERENCES SANBAY(MASB),
    MASBDEN CHAR(3) FOREIGN KEY REFERENCES SANBAY(MASB)
);
GO

CREATE TABLE CHUYENBAY (
    MACB CHAR(8) PRIMARY KEY,
    MATB CHAR(8) FOREIGN KEY REFERENCES TUYENBAY(MATB),
    MAMB CHAR(8) FOREIGN KEY REFERENCES MAYBAY(MAMB),
    NGAYKHOIHANH DATE NOT NULL,
    GIOKHOIHANH TIME NOT NULL,
    THOIGIANDUKIEN TIME NOT NULL,
	GIOHACANH TIME,
    SOGHEHANGTHUONGCONLAI INT,
    SOGHEHANGVIPCONLAI INT
);
GO

CREATE TABLE VAITRO (
    MAVT CHAR(8) PRIMARY KEY,
    TENVAITRO VARCHAR(50) NOT NULL
);
GO

CREATE TABLE NHANVIEN (
    MANV CHAR(8) PRIMARY KEY,
    TENNV NVARCHAR(30) NOT NULL,
    DIACHI NCHAR(50) NOT NULL,
    SODT VARCHAR(10) UNIQUE,
    NGAYSINH SMALLDATETIME NOT NULL,
    NGAYVAOLAM SMALLDATETIME NOT NULL,
    GIOITINH NCHAR(3) NOT NULL,
    EMAIL VARCHAR(50) UNIQUE,
    PASSWORD VARCHAR(25) NOT NULL,
    NGAYTAOTK DATETIME NOT NULL,
    MAVT CHAR(8) FOREIGN KEY REFERENCES VAITRO(MAVT)
);
GO

CREATE TABLE KHACHHANG (
    MAKH CHAR(8) PRIMARY KEY,
    TENKH NVARCHAR(30) NOT NULL,
    GIOITINH NCHAR(3) NOT NULL,
    NGAYSINH SMALLDATETIME NOT NULL,
    CCCD NVARCHAR(13) UNIQUE,
    NGAYCAP SMALLDATETIME,
    QUOCTICH NVARCHAR(30) NOT NULL,
    SODT VARCHAR(10) UNIQUE,
    EMAIL VARCHAR(50) UNIQUE,
    DIACHI NCHAR(50) NOT NULL,
    PASSWORD VARCHAR(25) NOT NULL,
    NGAYTAOTK DATETIME NOT NULL,
    MAVT CHAR(8) FOREIGN KEY REFERENCES VAITRO(MAVT)
);
GO

CREATE TABLE HOADON (
    MAHD CHAR(8) PRIMARY KEY,
    MANV CHAR(8) FOREIGN KEY REFERENCES NHANVIEN(MANV),
    MAKH CHAR(8) FOREIGN KEY REFERENCES KHACHHANG(MAKH),
    NGAYLAP DATE NOT NULL,
    SOVE INT,
    THANHTIEN MONEY,
	TINHTRANG INT
);
GO

CREATE TABLE HANGVE (
    MAHV CHAR(8) PRIMARY KEY,
    TENHANGVE NVARCHAR(20) NOT NULL
);
GO

CREATE TABLE VE (
    MAVE CHAR(8) PRIMARY KEY,
    MAHV CHAR(8) FOREIGN KEY REFERENCES HANGVE(MAHV),
    MACB CHAR(8) FOREIGN KEY REFERENCES CHUYENBAY(MACB),
    MAHD CHAR(8) FOREIGN KEY REFERENCES HOADON(MAHD),
    GHE CHAR(3) NOT NULL,
    GIAVE MONEY NOT NULL,
);
GO

--Thêm ràng buộc
-->Bảng NHANVIEN<--
ALTER TABLE NHANVIEN ADD CONSTRAINT CHK_SDT CHECK (SODT LIKE '0%');

ALTER TABLE NHANVIEN
ADD CONSTRAINT CHK_NGAYVAOLAM_NGAYSINH CHECK (NGAYVAOLAM > NGAYSINH);

ALTER TABLE NHANVIEN
ADD CONSTRAINT CHK_NGAYTAOTK CHECK (NGAYTAOTK >= NGAYVAOLAM AND NGAYTAOTK <= GETDATE());

--> Bảng KHACHHANG <--
ALTER TABLE KHACHHANG
ADD CONSTRAINT CHK_NGAYCAP_NGAYSINH CHECK (NGAYCAP > NGAYSINH);

ALTER TABLE KHACHHANG ADD CONSTRAINT CHK_SDT_KH CHECK (SODT LIKE '0%');

ALTER TABLE KHACHHANG
ADD CONSTRAINT CHK_NGAYTAOTK_KH CHECK (NGAYTAOTK <= GETDATE());

--> Bảng VE <--
ALTER TABLE VE
ADD CONSTRAINT CHK_GIAVE CHECK (GIAVE >=0)

--> Bảng CHUYENBAY <--
ALTER TABLE CHUYENBAY
ADD CONSTRAINT CHK_SOGHEHANGTHUONGCONLAI CHECK (SOGHEHANGTHUONGCONLAI >= 0);

ALTER TABLE CHUYENBAY
ADD CONSTRAINT CHK_SOGHEHANGVIPCONLAI CHECK (SOGHEHANGVIPCONLAI >= 0);

--> Bảng MAYBAY

ALTER TABLE MAYBAY
ADD CONSTRAINT CHK_SOGHETHUONG CHECK (SOGHETHUONG >= 0);

ALTER TABLE MAYBAY
ADD CONSTRAINT CHK_SOGHEVIP CHECK (SOGHEVIP >= 0);

--> Bảng HOADON
ALTER TABLE HOADON
ADD CONSTRAINT CHK_TINHTRANG CHECK (TINHTRANG = 0 OR TINHTRANG = 1);

--> Bảng TUYENBAY <--

ALTER TABLE TUYENBAY
ADD CONSTRAINT CHK_MASBDI_MASBDEN CHECK (MASBDI <> MASBDEN);

GO

--> TRIGGER <--
--Trigger kiểm tra độ tuổi của nhân viên ( lớn hơn 18 )

CREATE TRIGGER TRG_KIEMTRATUOI
ON NHANVIEN
AFTER INSERT, UPDATE
AS
BEGIN
    IF EXISTS (SELECT 1 FROM inserted WHERE DATEDIFF(YEAR, NGAYSINH, GETDATE()) < 18)
    BEGIN
        RAISERROR('Tuổi của nhân viên phải lớn hơn hoặc bằng 18.', 16, 1);
        ROLLBACK TRANSACTION;
    END;
END;

GO

--Trigger tạo mã tuyến bay
CREATE TRIGGER TRG_TUDONGTAO_MATB
ON TUYENBAY
INSTEAD OF INSERT
AS
BEGIN
    DECLARE @MASBDI CHAR(3), @MASBDEN CHAR(3), @MATB CHAR(8);

    SELECT @MASBDI = MASBDI, @MASBDEN = MASBDEN FROM inserted;

    -- Tạo mã tuyến bay từ mã sân bay đi và mã sân bay đến
    SET @MATB = @MASBDI + '-' + @MASBDEN;

    -- Update bảng TUYENBAY với mã tuyến bay mới
    INSERT INTO TUYENBAY (MATB, MASBDI, MASBDEN) VALUES (@MATB, @MASBDI, @MASBDEN)
END;

GO

--Trigger tính giờ hạ cánh của chuyến 
CREATE TRIGGER TRG_GIOHACANH ON CHUYENBAY
AFTER INSERT AS
BEGIN
    UPDATE CHUYENBAY
    SET GIOHACANH = CAST(DATEADD(MINUTE, DATEDIFF(MINUTE, 0, CAST(I.THOIGIANDUKIEN AS DATETIME)), CAST(C.GIOKHOIHANH AS DATETIME)) AS TIME)
    FROM CHUYENBAY C
    INNER JOIN inserted I ON C.MACB = I.MACB;
END

GO

--Trigger thêm số ghế thường và số ghế vip
CREATE TRIGGER TRG_SOGHECONLAI ON CHUYENBAY
AFTER INSERT AS
BEGIN
    UPDATE CHUYENBAY
    SET SOGHEHANGTHUONGCONLAI = M.SOGHETHUONG, SOGHEHANGVIPCONLAI = M.SOGHEVIP
    FROM CHUYENBAY C
    INNER JOIN inserted I ON C.MACB = I.MACB
    INNER JOIN MAYBAY M ON C.MAMB = M.MAMB
END
GO

--Trigger kiểm tra tính hợp lệ của ghế
CREATE TRIGGER TRG_THEMVE ON VE
INSTEAD OF INSERT AS
BEGIN
    DECLARE @tongghevip INT, @tongghethuong INT, @mahv CHAR(8), @ghe CHAR(3), @macb CHAR(8);
    DECLARE cur CURSOR LOCAL FOR SELECT MAHV, GHE, MACB FROM inserted;
	OPEN cur;
    FETCH NEXT FROM cur INTO @mahv, @ghe, @macb;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS(
            SELECT 1 FROM VE
            WHERE MACB = @macb AND GHE = @ghe
        )
		BEGIN
            PRINT N'Mã số ghế đã được đặt';
			FETCH NEXT FROM cur INTO @mahv, @ghe, @macb;
			RETURN;
        END
        ELSE
		BEGIN
            SELECT @tongghevip = SOGHEVIP, @tongghethuong = SOGHETHUONG FROM MAYBAY
            JOIN CHUYENBAY ON MAYBAY.MAMB = CHUYENBAY.MAMB
            WHERE CHUYENBAY.MACB = @macb;
            IF @mahv = 'F' AND (SELECT SOGHEHANGVIPCONLAI FROM CHUYENBAY WHERE MACB = @macb) > 0 AND @ghe > 0 AND @ghe <= @tongghevip
            BEGIN
                UPDATE CHUYENBAY
                SET SOGHEHANGVIPCONLAI = SOGHEHANGVIPCONLAI - 1
                WHERE MACB = @macb;
                INSERT INTO VE SELECT * FROM inserted WHERE MACB = @macb AND MAHV = @mahv AND GHE = @ghe;
            END
            ELSE IF (@mahv = 'J' OR @mahv = 'W' OR @mahv = 'Y') AND (SELECT SOGHEHANGTHUONGCONLAI FROM CHUYENBAY WHERE MACB = @macb) > 0 AND @ghe > @tongghevip AND @ghe <= (@tongghevip + @tongghethuong)
            BEGIN
                UPDATE CHUYENBAY
                SET SOGHEHANGTHUONGCONLAI = SOGHEHANGTHUONGCONLAI - 1
                WHERE MACB = @macb;
                INSERT INTO VE SELECT * FROM inserted WHERE MACB = @macb AND MAHV = @mahv AND GHE = @ghe;
            END
            ELSE
            BEGIN
                PRINT N'Ghế không hợp lệ.'
			    RETURN;
            END
			FETCH NEXT FROM cur INTO @mahv, @ghe, @macb;
        END
    END
    CLOSE cur;
    DEALLOCATE cur;
END;

GO

--Trigger update hóa đơn và tính tổng thành tiền 
CREATE TRIGGER TRG_CAPNHATHOADON ON VE
AFTER INSERT AS
BEGIN
    UPDATE HOADON
    SET SOVE = (SELECT COUNT(*) FROM VE WHERE MAHD = I.MAHD),
        THANHTIEN = (SELECT SUM(GIAVE) FROM VE WHERE MAHD = I.MAHD)
    FROM HOADON H
    INNER JOIN inserted I ON H.MAHD = I.MAHD;
END

GO
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

GO

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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BOT-ORN', 'BOT', 'ORN');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('JRB-MBX', 'JRB', 'MBX');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-CKE', 'TRG', 'CKE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('FDE-MBX', 'FDE', 'MBX');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PTT-FRO', 'PTT', 'FRO');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-TUA', 'MGR', 'TUA');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-SUT', 'MBX', 'SUT');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PTT-PTT', 'PTT', 'PTT');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('BOT-BOT', 'BOT', 'BOT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGD-ABK', 'MGD', 'ABK');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('OKJ-PJB', 'OKJ', 'PJB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-SKQ', 'ARS', 'SKQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SUT-OKJ', 'SUT', 'OKJ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TRG-CKE', 'TRG', 'CKE');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('WLW-BOT', 'WLW', 'BOT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('CKE-FRQ', 'CKE', 'FRQ');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-URC', 'TAB', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SQO-BBW', 'SQO', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KDP-ORN', 'KDP', 'ORN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ORN-FRN', 'ORN', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MMH-SAF', 'MMH', 'SAF');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MMH-MMH', 'MMH', 'MMH');
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
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('KSL-BBW', 'KSL', 'BBW');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('COF-URC', 'COF', 'URC');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('SAF-AMA', 'SAF', 'AMA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('TAB-PJB', 'TAB', 'PJB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('COF-TRG', 'COF', 'TRG');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-SYB', 'MBX', 'SYB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('GAV-TDA', 'GAV', 'TDA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MVK-SYB', 'MVK', 'SYB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('ARS-GAV', 'ARS', 'GAV');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-PTT', 'PPU', 'PTT');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('OKJ-TAB', 'OKJ', 'TAB');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('PPU-FRN', 'PPU', 'FRN');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MGR-TUA', 'MGR', 'TUA');
insert into TUYENBAY (MATB, MASBDI, MASBDEN) values ('MBX-SUT', 'MBX', 'SUT');

GO

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
GO

insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QO 997', 'AMA-NCE', 'Z3SU5Y', '2025/07/21', '4:06', '2:57');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AT 362', 'BKD-TRG', 'ZG6Z15', '2025/11/08', '21:46', '18:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LW 020', 'YWB-FRO', 'YPLXH5', '2025/07/15', '15:46', '6:54');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PJ 001', 'WLW-BOT', 'YL3LHE', '2025/04/26', '1:06', '0:06');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IG 452', 'ORN-NCE', 'Y3DFPY', '2025/04/16', '20:20', '14:44');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VH 352', 'KSL-SUT', 'Y2MJ8M', '2025/11/24', '18:13', '20:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NS 674', 'BLD-GAV', 'Z5O6KQ', '2025/11/02', '22:50', '4:09');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GX 201', 'LDS-FCM', 'ZG6Z15', '2025/06/24', '6:15', '11:21');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DE 995', 'BOT-PPU', 'ZS3VCX', '2025/11/14', '2:45', '16:43');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SO 116', 'TRG-ERG', 'ZGM912', '2025/12/15', '17:19', '1:13');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RA 632', 'TRG-KSL', 'ZG6Z15', '2025/12/02', '0:46', '17:06');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CJ 329', 'SWV-TDA', 'Z3SU5Y', '2025/01/30', '16:45', '10:16');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WI 057', 'BLD-GAV', 'YL3LHE', '2025/02/24', '20:26', '6:02');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QS 839', 'FDE-MBX', 'Y2MJ8M', '2025/12/24', '8:45', '8:33');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YP 305', 'SAF-AMA', 'Y3DFPY', '2025/02/24', '23:21', '22:55');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DF 740', 'SAF-WLW', 'ZQI5XW', '2025/08/27', '9:46', '16:43');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JK 999', 'FDE-MBX', 'YZ2IOF', '2025/12/04', '15:41', '6:36');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VL 928', 'HGU-CKE', 'Y3DFPY', '2025/09/22', '20:37', '2:40');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UI 232', 'BOT-LDS', 'ZS3VCX', '2025/05/15', '3:40', '2:28');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UL 806', 'MVK-TRG', 'Z3SU5Y', '2025/05/30', '18:41', '7:34');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YF 362', 'KSL-SUT', 'XVNM2Z', '2025/04/22', '7:20', '20:38');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CS 257', 'FCM-AMA', 'YPLXH5', '2025/06/05', '11:08', '17:18');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XF 402', 'NLS-FRN', 'YW8XMY', '2025/08/08', '21:32', '13:55');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MD 109', 'MGD-ABK', 'YZ2IOF', '2025/04/02', '10:35', '15:45');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EN 334', 'MGR-TUA', 'Y3DFPY', '2025/08/15', '20:16', '12:29');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VN 139', 'CKE-FRQ', 'ZQI5XW', '2025/01/20', '14:49', '23:13');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VB 885', 'SUT-OKJ', 'Y3DFPY', '2025/04/18', '4:33', '14:56');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RI 271', 'CKE-SWV', 'Y3DFPY', '2025/03/07', '10:51', '4:05');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZE 184', 'URC-WLW', 'XZPZGJ', '2025/08/11', '23:14', '9:06');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZU 161', 'ORN-FRN', 'YPLXH5', '2025/06/25', '3:47', '2:37');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GX 679', 'KDP-ORN', 'YL3LHE', '2025/02/21', '8:43', '12:55');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LI 649', 'GOB-SQO', 'YZ2IOF', '2025/05/18', '11:29', '18:11');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PO 705', 'ORN-BKD', 'YW8XMY', '2025/05/29', '20:59', '16:38');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MU 795', 'URC-PTT', 'ZS3VCX', '2025/03/16', '8:10', '11:26');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OT 330', 'TDA-LDS', 'ZGM912', '2025/05/03', '15:02', '9:24');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CD 263', 'FRO-SAF', 'Y9XRBH', '2025/06/09', '8:15', '4:35');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QW 044', 'SAF-AMA', 'XI1JDN', '2025/01/31', '16:58', '20:02');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IA 834', 'NCE-FRN', 'ZQI5XW', '2025/01/03', '18:51', '12:26');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EE 682', 'CKE-SAF', 'ZS3VCX', '2025/01/27', '7:37', '20:17');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZP 863', 'SAF-TDA', 'XI1JDN', '2025/11/04', '3:38', '21:08');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FM 573', 'OKJ-SQO', 'ZG6Z15', '2025/10/24', '2:15', '22:26');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RJ 751', 'HGU-TUA', 'Z3SU5Y', '2025/12/15', '21:08', '20:18');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GP 148', 'ABK-FCM', 'XRSEF9', '2025/01/01', '14:03', '18:53');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FZ 441', 'ABK-MVK', 'Y3DFPY', '2025/08/06', '15:09', '22:14');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KV 831', 'ORN-FRN', 'Y2MJ8M', '2025/02/14', '10:19', '12:13');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UX 023', 'TRG-CKE', 'ZQI5XW', '2025/10/05', '9:33', '11:14');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FT 190', 'ABK-TAB', 'ZG6Z15', '2025/09/04', '15:56', '2:52');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NE 668', 'BLD-CNW', 'Y3DFPY', '2025/05/26', '18:19', '23:23');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ID 364', 'HGU-GAV', 'ZS3VCX', '2025/12/21', '0:38', '22:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YS 207', 'ABK-BKD', 'YW8XMY', '2025/08/02', '17:56', '12:53');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XF 119', 'BOT-ORN', 'Y2MJ8M', '2025/10/20', '16:32', '9:13');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RS 632', 'BKD-MVK', 'YZ2IOF', '2025/06/08', '9:47', '22:57');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CC 450', 'MGR-NCE', 'YZ2IOF', '2025/04/27', '22:58', '8:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QF 474', 'NCE-SWV', 'Z5O6KQ', '2025/05/26', '13:56', '2:10');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NA 077', 'SQO-BBW', 'Z3SU5Y', '2025/04/04', '16:41', '6:04');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NR 260', 'HGU-CKE', 'ZGM912', '2025/11/26', '22:56', '10:46');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AH 272', 'MMH-SAF', 'YL3LHE', '2025/07/31', '22:00', '1:48');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EA 714', 'HGU-CKE', 'XI1JDN', '2025/06/26', '13:02', '17:43');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UI 252', 'WLW-FCM', 'ZG6Z15', '2025/08/12', '11:10', '10:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QH 964', 'PTT-FRO', 'XVNM2Z', '2025/09/23', '12:15', '8:08');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VP 100', 'NKD-BLD', 'YZ2IOF', '2025/01/29', '10:10', '15:11');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CU 286', 'AMA-TRG', 'YZ2IOF', '2025/12/09', '19:14', '18:14');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PE 344', 'MGR-PJB', 'Y3DFPY', '2025/07/01', '20:58', '17:20');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CK 021', 'TUA-BBW', 'Z3SU5Y', '2025/02/23', '7:38', '16:24');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VI 246', 'NKD-BLD', 'Y9XRBH', '2025/08/27', '23:04', '13:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IH 336', 'BLD-GAV', 'ZS3VCX', '2025/09/26', '12:06', '7:39');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QB 429', 'MGD-ABK', 'ZQI5XW', '2025/02/14', '3:57', '19:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FW 269', 'NKD-FRN', 'XZPZGJ', '2025/02/02', '10:46', '22:34');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WK 651', 'TUA-SWV', 'YL3LHE', '2025/04/25', '8:08', '15:18');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OB 839', 'FCM-AMA', 'ZG6Z15', '2025/03/26', '10:15', '8:29');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FQ 490', 'KSL-BBW', 'Z5O6KQ', '2025/01/02', '16:15', '16:40');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YX 198', 'TRG-AMA', 'ZQI5XW', '2025/06/27', '22:09', '15:52');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ML 770', 'JRB-MBX', 'ZG6Z15', '2025/01/25', '1:51', '20:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YR 162', 'TAB-SKQ', 'Y3DFPY', '2025/09/16', '13:58', '18:29');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IX 315', 'TRG-CKE', 'Z3SU5Y', '2025/11/22', '18:26', '3:32');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SH 048', 'TRG-AMA', 'Y3DFPY', '2025/03/03', '12:10', '13:30');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('BZ 794', 'ERG-ORN', 'YL3LHE', '2025/03/01', '21:38', '7:15');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GE 692', 'FDE-FRQ', 'Z5O6KQ', '2025/06/21', '19:40', '0:09');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WB 728', 'ABK-TAB', 'Z3SU5Y', '2025/01/22', '17:04', '1:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OC 854', 'YWB-FRO', 'XZPZGJ', '2025/02/19', '12:25', '22:23');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LV 508', 'ERG-TUA', 'YZ2IOF', '2025/12/16', '18:45', '17:16');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('US 277', 'TAB-FRQ', 'XRSEF9', '2025/04/29', '2:48', '18:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('TI 992', 'WLW-ERG', 'XZPZGJ', '2025/11/24', '10:46', '7:32');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AE 660', 'NCE-FRN', 'XZPZGJ', '2025/05/25', '18:28', '22:27');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LX 199', 'ARS-CNW', 'ZGM912', '2025/09/16', '1:51', '18:42');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IO 348', 'AMA-NCE', 'ZS3VCX', '2025/05/07', '4:28', '19:45');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZJ 357', 'FRN-TDA', 'YL3LHE', '2025/01/25', '16:22', '16:45');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SW 408', 'MMH-SAF', 'XZPZGJ', '2025/10/28', '5:28', '1:00');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MF 795', 'TUA-BBW', 'YZ2IOF', '2025/05/05', '18:46', '11:27');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('HD 186', 'CKE-SQZ', 'ZGM912', '2025/08/08', '20:39', '16:34');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CR 563', 'KSL-SWV', 'XI1JDN', '2025/11/06', '20:56', '9:42');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WW 742', 'SAF-TDA', 'YZ2IOF', '2025/03/16', '20:34', '12:47');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DM 930', 'OKJ-TAB', 'Z3SU5Y', '2025/05/20', '10:43', '21:08');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FR 949', 'WLW-TAB', 'XRSEF9', '2025/01/14', '2:19', '3:58');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('BX 202', 'TRG-KDP', 'Z3SU5Y', '2025/07/23', '15:12', '9:47');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZG 279', 'BKD-GAV', 'ZG6Z15', '2025/09/25', '17:37', '14:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GW 845', 'SAF-TDA', 'YW8XMY', '2025/03/24', '6:43', '19:26');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KT 165', 'WLW-TAB', 'YL3LHE', '2025/05/05', '10:31', '2:41');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LI 985', 'BBW-TAB', 'XRSEF9', '2025/10/26', '6:31', '7:34');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GV 052', 'WLW-FCM', 'Z5O6KQ', '2025/01/15', '0:38', '1:17');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ST 147', 'NLS-FRN', 'YZ2IOF', '2025/03/31', '19:34', '5:18');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WF 431', 'ERG-ORN', 'Y9XRBH', '2025/08/24', '7:33', '18:11');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MG 930', 'TUA-OKJ', 'Z5O6KQ', '2025/04/30', '2:20', '10:30');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FT 215', 'NKD-FRN', 'Y3DFPY', '2025/01/22', '13:39', '15:43');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CU 216', 'SWV-TDA', 'Y2MJ8M', '2025/03/01', '8:54', '9:54');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PI 359', 'MGR-MVK', 'YZ2IOF', '2025/09/03', '14:07', '15:07');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MH 757', 'MGR-KSL', 'Y3DFPY', '2025/04/08', '21:23', '1:04');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QF 239', 'MVK-TRG', 'XVNM2Z', '2025/04/13', '21:18', '21:36');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MP 271', 'HGU-CKE', 'XRSEF9', '2025/02/23', '22:23', '8:38');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RG 468', 'SWV-TDA', 'Z5O6KQ', '2025/03/22', '17:03', '21:02');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JZ 483', 'BOT-ORN', 'ZQI5XW', '2025/08/09', '20:28', '2:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YL 505', 'FCM-TAB', 'Y2MJ8M', '2025/09/05', '0:44', '0:08');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EB 303', 'MBX-ABK', 'YZ2IOF', '2025/07/02', '19:55', '19:09');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KH 340', 'BLD-GAV', 'YZ2IOF', '2025/01/20', '5:25', '17:51');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QF 607', 'MBX-SUT', 'ZG6Z15', '2025/03/04', '4:01', '16:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SR 280', 'TAB-SKQ', 'XRSEF9', '2025/08/21', '20:49', '21:42');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SJ 060', 'SKQ-GAV', 'Y9XRBH', '2025/04/08', '7:18', '0:56');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FT 589', 'CNW-ABK', 'Y9XRBH', '2025/09/27', '7:26', '13:20');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SE 323', 'LDS-FCM', 'Y2MJ8M', '2025/01/02', '23:25', '15:10');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EA 805', 'PTT-FDE', 'YW8XMY', '2025/09/30', '0:17', '19:40');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VR 146', 'TAB-URC', 'YL3LHE', '2025/01/08', '9:03', '0:32');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZP 458', 'SKQ-GAV', 'ZQI5XW', '2025/07/09', '8:16', '8:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LU 202', 'FRQ-SYB', 'ZGM912', '2025/12/27', '6:46', '23:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PC 520', 'COF-AMA', 'ZG6Z15', '2025/08/09', '1:06', '13:01');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AN 989', 'MBX-WLW', 'XRSEF9', '2025/05/29', '10:22', '19:20');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UD 378', 'KSL-SWV', 'Y2MJ8M', '2025/10/08', '23:07', '15:35');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ST 180', 'CKE-KSL', 'XI1JDN', '2025/09/09', '8:52', '2:25');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UF 497', 'GOB-SQO', 'Y2MJ8M', '2025/07/18', '10:42', '17:53');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GZ 512', 'CKE-SQZ', 'ZG6Z15', '2025/02/16', '0:04', '21:45');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('BC 789', 'KDP-AMA', 'ZGM912', '2025/02/06', '4:42', '22:48');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ND 911', 'COF-URC', 'XI1JDN', '2025/06/26', '11:11', '8:20');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JD 706', 'NCE-SQZ', 'XZPZGJ', '2025/06/15', '20:00', '16:57');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UF 966', 'FDE-MBX', 'YL3LHE', '2025/08/12', '9:34', '6:22');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KX 851', 'LDS-YWB', 'Z3SU5Y', '2025/06/12', '21:43', '16:24');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QZ 396', 'MGD-SUT', 'Z3SU5Y', '2025/04/03', '8:16', '14:31');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KB 938', 'ERG-SQZ', 'ZQI5XW', '2025/12/05', '9:22', '21:07');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('QM 350', 'URC-WLW', 'YL3LHE', '2025/12/11', '3:39', '1:46');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VX 674', 'OKJ-TAB', 'YL3LHE', '2025/11/13', '6:19', '17:27');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LT 512', 'ARS-JRB', 'Y2MJ8M', '2025/07/11', '4:05', '10:52');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XL 786', 'MMH-SAF', 'YW8XMY', '2025/02/24', '13:27', '19:49');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('HE 072', 'ERG-ORN', 'XI1JDN', '2025/01/19', '0:00', '8:31');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DY 653', 'ERG-SQO', 'XRSEF9', '2025/01/03', '14:12', '23:22');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OJ 008', 'NCE-FRN', 'Y3DFPY', '2025/05/04', '15:43', '1:46');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VB 795', 'BLD-GAV', 'XRSEF9', '2025/09/24', '0:32', '17:38');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VZ 503', 'MGR-MGD', 'XZPZGJ', '2025/02/13', '18:08', '6:23');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CI 813', 'CKE-FRQ', 'ZG6Z15', '2025/06/08', '13:39', '3:26');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MQ 793', 'SYB-TDA', 'Z3SU5Y', '2025/03/31', '1:54', '11:41');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DE 053', 'PPU-FRN', 'ZGM912', '2025/11/15', '6:03', '7:39');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DZ 316', 'SQO-BBW', 'XVNM2Z', '2025/04/09', '22:16', '4:20');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JR 712', 'FRO-SKQ', 'Y2MJ8M', '2025/12/26', '6:19', '0:57');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GV 164', 'PPU-JRB', 'ZQI5XW', '2025/07/19', '4:28', '8:26');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('SU 627', 'FRO-ABK', 'ZS3VCX', '2025/10/21', '8:45', '16:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GG 179', 'MGR-KSL', 'Y2MJ8M', '2025/02/27', '9:46', '16:13');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PI 349', 'MGR-TUA', 'YPLXH5', '2025/11/14', '14:43', '20:43');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('HD 430', 'TRG-CKE', 'XVNM2Z', '2025/02/20', '23:20', '0:21');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PJ 647', 'MVK-SYB', 'ZQI5XW', '2025/06/07', '20:42', '14:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JW 088', 'PTT-FDE', 'Y2MJ8M', '2025/10/05', '7:36', '19:56');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('RX 159', 'ERG-TUA', 'XRSEF9', '2025/11/27', '20:00', '15:05');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VA 877', 'NCE-HGU', 'Y9XRBH', '2025/04/06', '15:56', '20:25');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GT 100', 'TAB-PJB', 'Y9XRBH', '2025/05/06', '20:23', '2:31');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EI 901', 'ARS-BBW', 'Z3SU5Y', '2025/01/20', '21:30', '7:28');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VV 363', 'KSL-URC', 'Z3SU5Y', '2025/08/16', '6:31', '4:11');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VJ 397', 'COF-BBW', 'ZS3VCX', '2025/08/07', '15:39', '15:27');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CS 285', 'TRG-AMA', 'XRSEF9', '2025/02/05', '23:36', '11:17');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LP 806', 'TDA-SQO', 'YL3LHE', '2025/02/14', '22:21', '11:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XK 113', 'FRO-SKQ', 'Y3DFPY', '2025/01/05', '8:38', '7:56');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('WE 064', 'BBW-SQZ', 'Z3SU5Y', '2025/06/27', '20:38', '12:41');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NS 842', 'PJB-MBX', 'Z3SU5Y', '2025/09/15', '21:37', '14:11');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('CM 255', 'MMH-SQO', 'YZ2IOF', '2025/03/07', '18:42', '1:32');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('GH 241', 'WLW-FCM', 'Y3DFPY', '2025/08/27', '9:31', '20:09');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AC 133', 'SQO-BBW', 'Y2MJ8M', '2025/05/27', '7:52', '14:16');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('TP 671', 'KDP-FRN', 'ZGM912', '2025/05/26', '10:00', '4:30');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VV 600', 'GAV-ORN', 'YPLXH5', '2025/11/13', '6:09', '10:08');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('PK 064', 'CKE-SAF', 'XI1JDN', '2025/07/12', '9:52', '16:29');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('AG 553', 'BBW-AMA', 'YL3LHE', '2025/06/19', '10:03', '10:24');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VA 132', 'LDS-YWB', 'YW8XMY', '2025/04/08', '1:46', '9:55');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('EL 557', 'ORN-SAF', 'Y2MJ8M', '2025/04/19', '17:52', '15:12');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('TV 344', 'CKE-SQZ', 'Y3DFPY', '2025/12/21', '20:37', '20:52');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DV 657', 'SWV-FRQ', 'XZPZGJ', '2025/09/20', '19:57', '10:17');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('XY 772', 'GAV-TDA', 'ZS3VCX', '2025/06/08', '13:35', '18:17');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('NQ 204', 'ERG-ORN', 'Y3DFPY', '2025/06/11', '15:05', '4:35');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IJ 564', 'ARS-CNW', 'XRSEF9', '2025/04/27', '13:22', '13:47');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DC 306', 'SQO-BOT', 'XI1JDN', '2025/10/10', '4:37', '7:10');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FK 002', 'KSL-ARS', 'YZ2IOF', '2025/10/01', '19:06', '5:17');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YP 747', 'MMH-SQO', 'ZS3VCX', '2025/09/05', '2:58', '19:29');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('IF 068', 'NCE-FRN', 'XI1JDN', '2025/09/07', '18:01', '1:30');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZO 430', 'FRO-COF', 'ZS3VCX', '2025/11/21', '16:46', '2:47');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('MD 784', 'MMH-SAF', 'XZPZGJ', '2025/04/12', '20:42', '10:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('BL 389', 'MGR-NCE', 'XRSEF9', '2025/03/17', '23:37', '0:48');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('KG 314', 'KDP-WLW', 'XI1JDN', '2025/04/19', '0:59', '2:04');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('FH 258', 'KDP-FRN', 'YZ2IOF', '2025/09/03', '11:20', '8:07');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('VZ 667', 'OKJ-SQO', 'Z3SU5Y', '2025/10/07', '11:32', '20:56');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('YK 442', 'TDA-SQO', 'YL3LHE', '2025/02/03', '12:50', '21:50');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('DT 673', 'ABK-MVK', 'YPLXH5', '2025/03/24', '1:25', '9:20');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('OL 737', 'MBX-SUT', 'XI1JDN', '2025/08/26', '2:30', '20:59');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('LZ 930', 'TAB-SKQ', 'Y2MJ8M', '2025/07/04', '3:33', '20:40');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZL 530', 'FCM-SQO', 'ZQI5XW', '2025/10/21', '10:25', '0:21');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('ZH 266', 'BBW-AMA', 'Z3SU5Y', '2025/12/27', '14:33', '22:50');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('UZ 409', 'SAF-AMA', 'Y2MJ8M', '2025/11/12', '23:39', '17:36');
insert into CHUYENBAY (MACB, MATB, MAMB, NGAYKHOIHANH, GIOKHOIHANH, THOIGIANDUKIEN) values ('JS 595', 'SQZ-NLS', 'ZS3VCX', '2025/06/25', '15:58', '4:32');
GO

insert into HANGVE (MAHV, TENHANGVE) values ('F', 'First class');
insert into HANGVE (MAHV, TENHANGVE) values ('J', 'Business');
insert into HANGVE (MAHV, TENHANGVE) values ('W', 'Premium Economy');
insert into HANGVE (MAHV, TENHANGVE) values ('Y', 'Economy');

GO

insert into VAITRO (MAVT, TENVAITRO) values ('NV', 'Employee');
insert into VAITRO (MAVT, TENVAITRO) values ('KH', 'Customer');

GO

insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV033311', 'Jewelle Benezeit', '452 Elgar Terrace', '0782856301', '1977/09/17', '2022/05/28', 'F', 'jbenezeit0@youtube.com', 'mX7<L/DsK)2O', '2020/01/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV788838', 'Susan Secretan', '8 Jana Terrace', '0630103243', '1990/03/01', '1968/09/17', 'F', 'ssecretan1@jugem.jp', 'xQ4`#g{?<|N4tC#', '1986/04/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV770980', 'Kaile Densumbe', '4 Waywood Way', '0607808539', '1959/01/23', '1963/10/09', 'F', 'kdensumbe2@scientificamerican.com', 'rA3%l@}}88b&V', '2020/11/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV141151', 'Jeffie Semered', '9689 Lotheville Road', '0427585373', '1993/10/28', '1973/01/06', 'F', 'jsemered3@dot.gov', 'uM1%Kht%r', '2012/07/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV425018', 'Amabelle Sibbit', '12 Heath Center', '0219500504', '2001/12/20', '2004/07/24', 'M', 'asibbit4@etsy.com', 'pJ1"$y\wsV,', '2010/03/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV444738', 'Joya Sinnott', '08 Melrose Parkway', '0287613206', '1945/03/18', '1969/07/23', 'F', 'jsinnott5@answers.com', 'mT5(|}WNWb)i<M/', '1994/07/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV257221', 'Leon Cosgreave', '35099 Green Center', '0486008243', '2003/06/16', '1992/02/20', 'M', 'lcosgreave6@blog.com', 'dS2@Yq*.1v/~$q', '1981/02/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV885375', 'Daveen Gurney', '27 Tomscot Street', '0298490748', '1962/09/25', '2005/05/26', 'F', 'dgurney7@theguardian.com', 'dE1=r,iSEhx', '1985/09/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV022164', 'Danit Getcliff', '249 Beilfuss Terrace', '0386734711', '1995/03/16', '1971/11/06', 'F', 'dgetcliff8@dailymail.co.uk', 'wM6%''u6|aGwxq', '2013/01/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV928328', 'Carver Fitzpatrick', '31 Drewry Place', '0096523425', '1956/12/26', '2005/12/06', 'F', 'cfitzpatrick9@telegraph.co.uk', 'sX9%Y2UGM(+', '1982/01/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV556818', 'Cristi Castille', '1238 Bunker Hill Place', '0570247436', '1949/12/26', '1997/09/15', 'M', 'ccastillea@163.com', 'uN5)Rjq#{+', '1966/08/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV448685', 'Adelheid Costelloe', '2566 Sauthoff Park', '0009357810', '1953/03/11', '2019/02/25', 'F', 'acostelloeb@hugedomains.com', 'wC8<SaztBJE=b''s', '1979/01/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV036387', 'Clerc Biffen', '36108 Sugar Avenue', '0578064950', '2000/10/06', '2011/04/06', 'F', 'cbiffenc@nbcnews.com', 'fS2)$D&lYX', '1986/04/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV591214', 'Welch Malster', '0 Mayer Hill', '0626130368', '1991/08/01', '2000/04/04', 'F', 'wmalsterd@instagram.com', 'cX1@J3yC**\WJb@', '1977/06/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV176784', 'Lion Henlon', '9 Kings Terrace', '0458185062', '1966/05/09', '2003/06/12', 'M', 'lhenlone@state.tx.us', 'qD2~(sMH(?GhmL', '1984/11/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV002778', 'Zaria Wallege', '7694 Cottonwood Lane', '0419529688', '1955/04/18', '1990/08/30', 'F', 'zwallegef@google.co.uk', 'sS9<#U!B\}U{&Mu', '1984/04/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV855583', 'Laurie Carlino', '91551 Nova Avenue', '0337836797', '1990/03/30', '2010/07/21', 'M', 'lcarlinog@ibm.com', 'jW1`O_Ak{A>@,7', '1994/11/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV922561', 'Carrissa Bromage', '71206 International Point', '0166942036', '1993/09/19', '2002/10/24', 'M', 'cbromageh@webeden.co.uk', 'nV9.kGizI0j4k', '1986/10/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV081412', 'Selia Tunnick', '8 Dexter Avenue', '0486694281', '1985/12/02', '2016/08/31', 'M', 'stunnicki@nps.gov', 'dO8!EIklNHoMv5A', '2015/10/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV019537', 'Rianon Jones', '907 Bluestem Point', '0999251445', '1971/08/29', '1970/08/08', 'F', 'rjonesj@usa.gov', 'qB5.~h6(', '2008/04/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV797940', 'Noble Joll', '9221 Maple Wood Avenue', '0784302929', '1947/04/22', '1965/08/27', 'F', 'njollk@cloudflare.com', 'gU5<0)@<pFQ3qxqM', '2005/09/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV941361', 'Marten Storrie', '6 Carey Alley', '0972689145', '1981/10/22', '1965/04/27', 'M', 'mstorriel@arstechnica.com', 'fU0$S>WU', '2003/12/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV441589', 'Concettina Tchir', '2 Vernon Trail', '0860300395', '1966/03/23', '1969/01/08', 'M', 'ctchirm@liveinternet.ru', 'yJ0<(|RYA,!0', '1978/12/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV567692', 'Lou Denisyev', '571 Elka Trail', '0636433364', '1950/07/25', '2021/05/15', 'M', 'ldenisyevn@oracle.com', 'oV6)=nDAzq3', '1999/04/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV634541', 'Amabelle Wiley', '07376 Southridge Terrace', '0398688641', '1946/09/27', '2014/02/05', 'M', 'awileyo@printfriendly.com', 'pP6*09DUm', '2010/06/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV430597', 'Linn Fishburn', '1347 Banding Street', '0028171878', '1948/05/01', '1996/12/10', 'M', 'lfishburnp@nps.gov', 'dU3(cX6a$L"BqUTp', '2004/02/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV675961', 'Jackie Eldritt', '1 Fuller Parkway', '0732384992', '1968/03/09', '1989/02/01', 'M', 'jeldrittq@amazonaws.com', 'cN5%t1GH*M(,t', '2021/09/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV518097', 'Frazer Wrathall', '3 Mariners Cove Park', '0059641579', '1967/06/07', '1997/08/20', 'F', 'fwrathallr@netlog.com', 'eB5%%ps.m\rz8(6', '2007/06/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV025466', 'Davine Wrought', '73683 Marcy Lane', '0408757002', '1962/09/01', '1997/08/22', 'M', 'dwroughts@scientificamerican.com', 'pB8,X0e''WU3Yr|/', '2009/01/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV276093', 'Rhett Juszczyk', '47 Longview Parkway', '0946852161', '1989/07/27', '1976/06/21', 'F', 'rjuszczykt@etsy.com', 'uV9$5/?1w3OkaHQ', '1999/09/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV558499', 'Veronica Wyldish', '40432 Caliangt Trail', '0042146509', '1989/08/12', '2011/03/31', 'F', 'vwyldishu@twitter.com', 'gP7''%Ng?|Ye`(Xb', '1971/12/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV747397', 'Binni Spada', '1470 Southridge Center', '0456089600', '1951/12/13', '1966/04/15', 'F', 'bspadav@51.la', 'oZ7%WZ6i{G''', '2022/08/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV980129', 'Shannan Badman', '21499 Becker Pass', '0246256715', '1962/08/20', '2013/02/28', 'F', 'sbadmanw@oakley.com', 'jL4{`53XOMiq', '1966/12/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV590742', 'Bryce Meffin', '50221 Arapahoe Trail', '0601545618', '1976/01/23', '1998/11/13', 'F', 'bmeffinx@techcrunch.com', 'dQ8<''W6Cu2x', '1970/08/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV098080', 'Ado Melliard', '81365 Sommers Circle', '0457294443', '1955/10/03', '2015/12/29', 'M', 'amelliardy@hugedomains.com', 'nY4?5v+p&*36J', '2001/04/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV814569', 'Ewan Bastow', '01291 Crescent Oaks Crossing', '0499780140', '1954/04/05', '2017/05/27', 'F', 'ebastowz@booking.com', 'eG7"L@y)', '2010/10/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV634749', 'Violetta OIlier', '63 Summer Ridge Point', '0111927536', '1965/03/20', '1997/07/26', 'F', 'voilier10@imdb.com', 'iP5@6SFv', '2022/11/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV940794', 'Verna Peidro', '52398 Wayridge Parkway', '0533103173', '1971/09/16', '1990/03/16', 'M', 'vpeidro11@latimes.com', 'kC5*X(w}cn2FR', '2009/01/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV060548', 'Bill Furze', '51 Mitchell Parkway', '0091059005', '1994/02/03', '1992/06/28', 'F', 'bfurze12@geocities.com', 'xW7)6~eN(X5&9I8', '1995/06/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV829324', 'Jennette Abba', '42 Stone Corner Avenue', '0650418589', '1958/12/07', '2021/10/09', 'F', 'jabba13@paypal.com', 'iF1=AZFTK90', '1988/01/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV550817', 'Danila Sprionghall', '26470 Melby Hill', '0261142847', '1963/01/10', '1987/05/27', 'F', 'dsprionghall14@stumbleupon.com', 'lK8$8P#VEv', '2022/09/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV264057', 'Haily Biddlestone', '7 Morrow Way', '0289464052', '1983/09/01', '2005/02/03', 'F', 'hbiddlestone15@walmart.com', 'xA7*&6m/Mg', '2016/01/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV838975', 'Adolph Woolatt', '42193 Farragut Plaza', '0838873311', '1994/09/07', '1997/03/07', 'F', 'awoolatt16@illinois.edu', 'mR7{4KD/+', '1979/09/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV524840', 'Tiffie Radolf', '58086 Moulton Circle', '0559868979', '1950/06/09', '2006/12/12', 'M', 'tradolf17@china.com.cn', 'qO8_qj&66', '2008/09/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV143361', 'Shina Rodinger', '96596 Sommers Terrace', '0035037976', '1985/11/05', '2022/06/16', 'M', 'srodinger18@pen.io', 'gQ1|T,~dc4', '1977/09/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV990623', 'Doria Bertelsen', '6296 Loomis Pass', '0993366988', '1997/05/18', '2010/07/05', 'F', 'dbertelsen19@about.com', 'tP8{V2bxnxy%4c', '1994/11/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV134615', 'Levon Brunet', '58 Evergreen Place', '0360523040', '1979/07/02', '1972/05/22', 'F', 'lbrunet1a@reverbnation.com', 'zO9={jC.hzusXh', '2013/07/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV193223', 'Rosemarie Dansie', '67128 Grayhawk Lane', '0908448737', '2005/12/19', '2001/09/22', 'M', 'rdansie1b@xrea.com', 'bF3<{G+t', '1989/07/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV620875', 'Lanita Gregor', '030 Drewry Drive', '0169422467', '1977/12/03', '2005/01/12', 'F', 'lgregor1c@cnet.com', 'kE2<VwCD4yg*uD', '1964/06/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV559552', 'Archibold Jonathon', '6651 Manley Junction', '0821950454', '1962/03/20', '2016/06/13', 'M', 'ajonathon1d@spotify.com', 'vF1\?cJ&<E{q#oK', '1966/06/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV632380', 'Rycca Youll', '8914 Dovetail Way', '0629221976', '1993/08/31', '1984/09/26', 'F', 'ryoull1e@webs.com', 'dQ2/_Cpl=|zt', '2014/12/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV465924', 'Den Danielsson', '7 Maryland Center', '0519933783', '1964/05/14', '2014/04/01', 'M', 'ddanielsson1f@ifeng.com', 'oH4,<0|*51b?', '2001/02/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV992206', 'Orsa Reaper', '2 Packers Avenue', '0611294533', '2001/11/20', '1971/02/01', 'M', 'oreaper1g@samsung.com', 'gY0&X5R6=U', '1992/04/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV863210', 'Andrew Matonin', '43 Canary Street', '0185142274', '1985/01/02', '1964/07/27', 'M', 'amatonin1h@nytimes.com', 'dD2`MDk/"F)igl,', '2004/07/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV946685', 'Ray Duxfield', '209 Drewry Street', '0533534627', '1947/02/15', '2000/07/16', 'M', 'rduxfield1i@facebook.com', 'oW7"FMnfBcOPR', '2004/06/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV923295', 'Brandice Soigne', '813 Bultman Alley', '0060365986', '1997/04/04', '2016/05/29', 'M', 'bsoigne1j@prlog.org', 'hC2>$/K8Wg', '2004/11/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV049635', 'Dexter Collinge', '73 Center Hill', '0194543969', '2004/01/01', '2002/02/08', 'M', 'dcollinge1k@state.gov', 'qP2*zd66ws8', '2003/10/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV085281', 'Ailsun Beaven', '27036 Hoffman Plaza', '0732596324', '2003/06/19', '2014/01/10', 'F', 'abeaven1l@acquirethisname.com', 'kA8}+z~JSULswY&o', '2018/12/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV787213', 'Minne Walsom', '06799 John Wall Plaza', '0987188925', '1959/10/06', '1980/01/28', 'M', 'mwalsom1m@java.com', 'sQ0(Qupk+PO', '1981/05/31', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV170760', 'Thomasin Abrahamsen', '0 Portage Way', '0635780511', '1986/05/26', '2014/11/12', 'F', 'tabrahamsen1n@tamu.edu', 'bJ3*~zk9vk|.', '2008/02/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV620588', 'Sergeant Dackombe', '6552 Norway Maple Parkway', '0657834793', '1959/04/02', '2022/04/28', 'F', 'sdackombe1o@rambler.ru', 'hL4|3cOG&+yX', '2009/09/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV364363', 'Devonne Deeman', '6868 Sommers Plaza', '0759035957', '1988/11/13', '1970/10/18', 'M', 'ddeeman1p@sphinn.com', 'zZ6/qq,eNU', '1982/10/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV240842', 'Westbrooke Jell', '9985 Clemons Circle', '0639620476', '1981/01/14', '2010/06/05', 'F', 'wjell1q@merriam-webster.com', 'kL3`Jxfv!JH}lY', '1989/03/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV223401', 'Sherlocke Rallinshaw', '20201 Hanover Point', '0963913902', '1951/09/02', '1964/02/20', 'M', 'srallinshaw1r@samsung.com', 'aE0(Ng<F!0Z40jQ', '1970/12/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV531991', 'Anthony Anderbrugge', '0442 Spaight Parkway', '0244935684', '1969/09/06', '1987/07/17', 'M', 'aanderbrugge1s@unesco.org', 'aW4"xQVU', '1994/10/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV122667', 'Corri Tranmer', '6239 Roxbury Avenue', '0204019287', '1999/11/01', '2009/07/06', 'M', 'ctranmer1t@wp.com', 'zN0`3vP!ECxZ', '1998/08/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV711456', 'Adoree Blaschek', '4554 Blackbird Trail', '0834800671', '1973/07/07', '1986/01/11', 'M', 'ablaschek1u@mysql.com', 'mD6|zu|u', '2005/10/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV093390', 'Verla Castagnaro', '44 Westport Drive', '0527289722', '2005/02/04', '1969/11/25', 'F', 'vcastagnaro1v@blogs.com', 'mD1=Xzq9$Gnuc', '2004/11/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV755441', 'Toddy Dorling', '6 Hermina Terrace', '0265044837', '1978/08/28', '1971/09/21', 'F', 'tdorling1w@storify.com', 'pP2>A@Wk1gmoUZ', '2019/03/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV069236', 'Maribel McGoon', '2786 Ilene Road', '0472447137', '1976/04/27', '2001/05/16', 'M', 'mmcgoon1x@time.com', 'vI7,<p{KD%C)RRA)', '1967/08/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV941879', 'Cilka Espinho', '4 Mcbride Circle', '0673723766', '1948/09/07', '1993/11/10', 'M', 'cespinho1y@scribd.com', 'nU0<3+TRE1qi)Vo~', '2006/05/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV160330', 'Cathryn Bellows', '3827 Huxley Alley', '0099687594', '1999/12/16', '1967/02/11', 'M', 'cbellows1z@oaic.gov.au', 'uW2(F?ea', '2011/12/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV355812', 'Vida Fetter', '7654 Hoard Way', '0288774914', '1950/01/14', '2003/12/28', 'F', 'vfetter20@booking.com', 'hY5`nXBNW', '1975/05/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV234236', 'Charlton Tindley', '531 Surrey Hill', '0451341375', '1947/08/19', '2010/08/01', 'M', 'ctindley21@wikimedia.org', 'pC1&N8j7yqQ|&', '1973/08/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV787829', 'Winslow Jacklin', '75 Russell Court', '0955510528', '1949/01/02', '2008/03/09', 'F', 'wjacklin22@cyberchimps.com', 'fI4.aptY}a!Trh''', '1972/04/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV078538', 'Sharia Gibbings', '602 Granby Way', '0358544739', '2002/01/05', '2013/08/21', 'F', 'sgibbings23@taobao.com', 'wD3(LOaf', '2019/01/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV004569', 'Pansie Leythley', '2428 Coleman Junction', '0400300278', '1951/03/31', '1967/04/30', 'M', 'pleythley24@prweb.com', 'vP5+\RQ|#=d|ddw0', '1964/01/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV042239', 'Suzann Longcake', '82 Clemons Alley', '0044615761', '1980/01/07', '1997/02/26', 'F', 'slongcake25@ning.com', 'aQ8=K#kugv$B', '1970/11/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV175134', 'Shayne Counihan', '3 Scott Lane', '0420146921', '1986/05/01', '2004/04/09', 'M', 'scounihan26@tripadvisor.com', 'zI2%D*''Wm*Iom%8', '1964/08/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV012703', 'Jobie Muckart', '493 Cottonwood Road', '0679993048', '1971/11/21', '2009/07/30', 'M', 'jmuckart27@soundcloud.com', 'kO0){i@Qk,9', '1983/04/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV901134', 'Waldo Benedit', '99 Eliot Trail', '0399871432', '1977/10/20', '2004/07/17', 'F', 'wbenedit28@weibo.com', 'yJ2+n>ooKta6W+T3', '2010/08/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV790581', 'Martita Denyukhin', '7 John Wall Point', '0964456517', '1977/08/26', '1991/10/23', 'M', 'mdenyukhin29@bluehost.com', 'jK8>LM>&rph', '2021/12/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV779451', 'Tripp Rutledge', '371 Declaration Trail', '0641081964', '1969/12/17', '2010/03/01', 'F', 'trutledge2a@fc2.com', 'aG7*t,lT@$G%>', '1991/11/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV336685', 'Roch Manuello', '69666 Debra Parkway', '0833372027', '1952/01/31', '1976/06/02', 'F', 'rmanuello2b@hao123.com', 'iD5|&"*u,j', '2006/05/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV761216', 'Gertruda Bosdet', '7 Pankratz Road', '0780969443', '1972/01/19', '1984/02/15', 'M', 'gbosdet2c@opera.com', 'lJ3@,e\{CW3CWg', '1982/04/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV659802', 'Davina Edmondson', '33117 Bashford Parkway', '0351938606', '1966/01/08', '2010/12/21', 'F', 'dedmondson2d@e-recht24.de', 'hU2+3DnVWg', '2017/07/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV228193', 'Bran Shead', '936 Coolidge Parkway', '0331986061', '1963/03/03', '2006/07/15', 'F', 'bshead2e@smh.com.au', 'yA5%pFN7iQ', '1965/06/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV890913', 'Hersh Opdenorth', '57226 Washington Park', '0885455246', '1967/02/16', '1974/09/06', 'F', 'hopdenorth2f@yale.edu', 'wY2*\%hvOe', '2015/02/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV439113', 'Danny McAlister', '7514 Northridge Way', '0791085836', '1948/03/11', '1966/07/18', 'F', 'dmcalister2g@ucsd.edu', 'tH3#P8Cy&b9', '1978/06/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV467438', 'Cheryl Lonnon', '0 Bultman Plaza', '0210103011', '1962/04/23', '2016/10/18', 'F', 'clonnon2h@disqus.com', 'vK8~?i''Y3w`', '1973/12/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV760088', 'Laureen Kalinovich', '15068 Sutherland Street', '0497064022', '1978/11/12', '1990/09/18', 'M', 'lkalinovich2i@weather.com', 'cE6|S/c{&)kpy_v', '1971/06/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV383537', 'Deck Eilers', '90285 Utah Street', '0523722989', '2001/11/14', '1969/01/28', 'M', 'deilers2j@theglobeandmail.com', 'jA0|Jo0gdPX', '2024/05/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV677204', 'Ardath MacFayden', '1 Esch Trail', '0307123506', '2001/03/19', '1964/12/26', 'F', 'amacfayden2k@loc.gov', 'bM0(#HZG#~en?', '1988/09/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV038067', 'Dodie Picott', '55171 Lindbergh Drive', '0299527842', '1998/01/18', '2005/01/02', 'F', 'dpicott2l@theatlantic.com', 'uT4!xwZgP8', '1991/03/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV064000', 'Vic Engall', '23090 Grasskamp Park', '0866085209', '1961/01/07', '1972/03/27', 'M', 'vengall2m@yellowbook.com', 'nY0<z|OH', '1970/02/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV254096', 'Reg Wigmore', '42187 Mccormick Terrace', '0520334948', '1978/04/07', '2010/01/18', 'M', 'rwigmore2n@360.cn', 'iJ9~utgCnEtF', '1991/06/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV856387', 'Annie Elcy', '0 Hoard Park', '0023320169', '2003/08/19', '1977/06/03', 'F', 'aelcy2o@scientificamerican.com', 'jO8=12pf!', '1985/05/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV266414', 'Geraldine Mepsted', '81 Susan Way', '0679845058', '1983/05/18', '2016/03/02', 'F', 'gmepsted2p@trellian.com', 'dI8(\p3H=lu$', '1979/07/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV359684', 'Grover MacShirie', '6 Pawling Pass', '0558846593', '2000/09/17', '1995/07/03', 'M', 'gmacshirie2q@bbc.co.uk', 'fF4_A2(b''ra+ht/6', '2014/08/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV850462', 'Rebecka Brigdale', '56240 Springs Junction', '0176335672', '1977/06/21', '2008/09/08', 'M', 'rbrigdale2r@berkeley.edu', 'nF7.Tkk6rz{1{9~', '2015/10/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV129652', 'Leena Olenchikov', '192 Stuart Junction', '0695030717', '1980/05/19', '1993/10/25', 'F', 'lolenchikov2s@nps.gov', 'gF3?k#qjTEw)E8qD', '1993/10/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV762294', 'Lotta Carnihan', '7636 Armistice Trail', '0387019142', '2002/08/23', '1967/01/06', 'M', 'lcarnihan2t@gnu.org', 'fX9,N.|_}%uZLh2F', '1994/01/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV839199', 'Idette Grigoli', '48012 Bartillon Terrace', '0698672494', '1982/07/09', '1977/10/11', 'F', 'igrigoli2u@skype.com', 'eM8{xn+SS.F?!5C', '1963/02/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV790295', 'Pearl Mowen', '529 Golf View Plaza', '0648882946', '1966/09/20', '2017/06/24', 'F', 'pmowen2v@rediff.com', 'mH2$hzG6h', '1972/02/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV735464', 'Chase Charette', '2280 Thackeray Way', '0437313759', '1964/09/01', '2006/03/22', 'F', 'ccharette2w@omniture.com', 'lW2)A3GCX', '2022/05/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV240888', 'Skell Hotchkin', '7336 Washington Street', '0909022702', '1959/02/24', '1974/11/01', 'M', 'shotchkin2x@pagesperso-orange.fr', 'uV7.8!2OT{q>Y~', '2017/10/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV391581', 'Woodrow Baumaier', '87231 3rd Lane', '0849016900', '1972/06/11', '1977/11/14', 'F', 'wbaumaier2y@pcworld.com', 'aX1.KKfl$x', '1990/04/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV674774', 'Adrea Sibly', '57 Arapahoe Trail', '0107963963', '1981/06/11', '2015/10/04', 'F', 'asibly2z@eventbrite.com', 'eY8/G&ndEM9o', '2007/02/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV480270', 'Darelle Cawt', '2 Veith Court', '0778158195', '1965/06/25', '1982/03/01', 'F', 'dcawt30@omniture.com', 'zQ1{_3?9eo', '1994/06/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV502017', 'Beth Bryceson', '4477 Miller Drive', '0930606899', '1981/11/14', '1991/06/04', 'M', 'bbryceson31@thetimes.co.uk', 'qZ9{I<cvz', '1970/10/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV052437', 'Lorin Kettlewell', '41 Eagle Crest Court', '0440573050', '1999/05/27', '2014/10/06', 'F', 'lkettlewell32@opensource.org', 'aI1<ubu*`F0F', '1982/03/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV661276', 'Leeann Flannigan', '7 Buhler Court', '0555730465', '2002/07/06', '2012/04/21', 'F', 'lflannigan33@bbb.org', 'yO0>C"1u/92}', '1978/01/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV221677', 'Farr Higgen', '95 Grayhawk Parkway', '0793963274', '1971/11/20', '2015/05/16', 'F', 'fhiggen34@google.com', 'qB2`?sT~eQIJ6Kid', '2001/07/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV958292', 'Clyde McNysche', '9824 Merry Trail', '0948765491', '1946/05/18', '2003/07/03', 'F', 'cmcnysche35@zdnet.com', 'nG0~X5s{@', '1963/10/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV619570', 'Olenka Attyeo', '794 Hazelcrest Alley', '0904569240', '1953/05/24', '1981/02/16', 'F', 'oattyeo36@gizmodo.com', 'oH3&2sf$', '1999/03/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV925832', 'Silvester Bambrick', '0 Mifflin Hill', '0663817395', '1948/05/24', '1990/05/28', 'F', 'sbambrick37@imdb.com', 'jD0?9OJ)H#fClT', '2010/11/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV188613', 'Lindsay Drance', '7851 Lotheville Trail', '0748626756', '1993/03/25', '1966/09/24', 'F', 'ldrance38@spotify.com', 'nU1!Y6ViBa', '1989/09/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV659671', 'Gwenette Moxstead', '52678 Johnson Way', '0336102247', '1959/01/25', '1974/02/17', 'M', 'gmoxstead39@psu.edu', 'gD7/mAg$_jBks', '2020/07/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV257118', 'Roxane Youdell', '4351 Northport Avenue', '0227070589', '1979/07/27', '1991/03/11', 'M', 'ryoudell3a@ow.ly', 'mZ5?~V0J9E`>', '1978/12/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV510405', 'Nita Thackwray', '3110 Holmberg Center', '0019095935', '1984/10/27', '1988/10/06', 'M', 'nthackwray3b@google.ca', 'hI3.lm1''zIHa', '2004/01/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV125352', 'Morgan Perview', '439 Red Cloud Plaza', '0223980100', '1975/10/23', '1986/09/14', 'M', 'mperview3c@epa.gov', 'iH8)a@''f!a,X`', '1978/05/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV868930', 'Claudianus Wallage', '24183 Pine View Avenue', '0109298686', '1985/02/17', '2012/10/01', 'M', 'cwallage3d@diigo.com', 'uY4,Aq(O', '1963/06/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV380829', 'Vikky Winston', '1 Arizona Street', '0350678283', '1990/10/02', '2017/10/02', 'M', 'vwinston3e@amazon.co.jp', 'bM1/xRy5B2U(T', '1976/08/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV301963', 'Heddi Donnan', '37 La Follette Drive', '0679283593', '1989/10/06', '1981/06/20', 'F', 'hdonnan3f@shop-pro.jp', 'aH3@log$098H/y', '1973/09/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV960953', 'Merrili Tombs', '63 Springview Junction', '0695510141', '1968/01/14', '2009/06/04', 'F', 'mtombs3g@youku.com', 'qB3\Z/CmNo?Bmnhi', '1969/08/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV082714', 'Kendal Cartin', '136 American Point', '0288678173', '1975/10/31', '2005/10/10', 'M', 'kcartin3h@bloglovin.com', 'xR7$&bCHB2u', '1978/05/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV106103', 'Talya Awdry', '053 Briar Crest Parkway', '0086954944', '1973/06/23', '2009/03/28', 'M', 'tawdry3i@e-recht24.de', 'wI8)f\NOaNe', '1986/07/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV620275', 'Suzette Purtell', '3250 Debs Trail', '0539373282', '2003/04/07', '2022/05/11', 'F', 'spurtell3j@jalbum.net', 'pN2{G<YqQU', '2007/10/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV915819', 'Natty Abeau', '577 Tennessee Alley', '0097155793', '1998/01/22', '1977/10/11', 'M', 'nabeau3k@omniture.com', 'wH8(E''4yD\z', '2006/04/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV041942', 'Nate Tindle', '8259 Logan Lane', '0339766279', '1960/02/13', '1990/07/15', 'F', 'ntindle3l@samsung.com', 'jT2>D|9_m+"r''mh}', '1994/08/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV676162', 'Graeme Izaac', '6 Hanson Center', '0765952239', '1948/10/05', '1972/10/16', 'F', 'gizaac3m@indiegogo.com', 'zC3)%9#GwnWZ/_7@', '1993/02/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV132568', 'Cornie Kerman', '333 Reindahl Terrace', '0919694626', '1968/06/28', '1999/12/11', 'M', 'ckerman3n@ucla.edu', 'gX0.BYC~4u{P1Z{', '2010/10/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV945233', 'Blair Mar', '73 Waxwing Circle', '0143384540', '1949/10/30', '1973/08/11', 'F', 'bmar3o@ycombinator.com', 'rX9+W_M)Z}#>_k}n', '2011/08/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV321671', 'Cherey Truman', '81 Fieldstone Park', '0103403839', '1995/05/18', '1968/12/11', 'M', 'ctruman3p@columbia.edu', 'vY0|00$x', '1983/04/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV253335', 'Ruben Raymen', '34095 Clyde Gallagher Alley', '0832413147', '1951/11/02', '1984/05/25', 'F', 'rraymen3q@yahoo.co.jp', 'zM4<RC~4E}U', '1987/03/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV899968', 'Danella Friedenbach', '16805 Fallview Parkway', '0965635577', '1961/11/11', '2024/04/21', 'M', 'dfriedenbach3r@weibo.com', 'sK1*TGD(g4Kz)MFn', '1988/06/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV544650', 'Hatti Townson', '0 Erie Drive', '0445843245', '2002/01/28', '1973/03/22', 'F', 'htownson3s@gnu.org', 'nC5\@#|@JWL', '1988/08/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV875495', 'Eveleen Cayser', '21337 Morningstar Point', '0998756303', '1973/08/12', '1996/09/08', 'F', 'ecayser3t@china.com.cn', 'mQ5|@'')j?ZR', '2024/01/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV327641', 'Harold Telega', '478 Badeau Plaza', '0256841895', '1953/05/15', '1972/10/18', 'M', 'htelega3u@edublogs.org', 'uS2#Jxu$', '2016/07/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV392904', 'Barbe Trotman', '3335 Norway Maple Plaza', '0737108287', '1989/11/27', '2007/07/26', 'F', 'btrotman3v@networkadvertising.org', 'cU0@P,/Z.G`U', '1990/06/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV633952', 'Scarface Houndsom', '92 Bultman Way', '0471030395', '1965/03/01', '1989/01/09', 'M', 'shoundsom3w@pagesperso-orange.fr', 'yT2''cjYn\#t', '1974/08/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV982793', 'Stoddard Gossipin', '2 Artisan Avenue', '0138342629', '1983/08/28', '1994/07/08', 'M', 'sgossipin3x@ning.com', 'oF5{F23O`''WNX?', '1986/01/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV060507', 'Marcos Fetherstonhaugh', '86 Scofield Circle', '0101827144', '1946/03/19', '1986/03/26', 'M', 'mfetherstonhaugh3y@google.cn', 'vW5){X9D>@', '2015/10/31', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV016153', 'Larisa Kedslie', '7145 Ridgeway Trail', '0015261644', '1984/02/23', '2008/06/03', 'M', 'lkedslie3z@ed.gov', 'kG9{&Wj7aQL~', '2000/01/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV411967', 'Oralia Averall', '5 Lakewood Circle', '0609475546', '2001/09/24', '1967/02/15', 'M', 'oaverall40@ucla.edu', 'cJ6(dVQ".Fmyp_.\', '1970/01/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV502796', 'Munmro Ravel', '0 Haas Way', '0662572967', '1975/04/23', '2014/06/29', 'F', 'mravel41@sitemeter.com', 'xY6,#.DNb', '1972/05/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV950327', 'Sunshine Barkway', '4 Fairfield Pass', '0617834052', '1966/11/08', '1999/11/13', 'F', 'sbarkway42@slashdot.org', 'iC0&L#J~*s$0z9', '2008/08/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955988', 'Baron Corns', '334 Carey Hill', '0733519659', '1955/07/10', '1967/10/19', 'M', 'bcorns43@pcworld.com', 'gQ2/%f2tDq>T@xEy', '1983/11/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV092168', 'Humberto Conor', '8138 Kennedy Parkway', '0557317845', '1988/04/11', '1973/12/23', 'M', 'hconor44@ucoz.com', 'eV7`aa&u$s>?Z', '1978/03/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV235583', 'Tricia Pardi', '9 Forest Dale Road', '0064740032', '1989/11/21', '2005/02/25', 'M', 'tpardi45@sourceforge.net', 'iS1$/Z''x5M', '1986/10/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV650255', 'Delbert Chedgey', '8 Shelley Hill', '0345500144', '1989/01/21', '2012/10/27', 'F', 'dchedgey46@oakley.com', 'eV2|04|0pTS4', '1999/02/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV288830', 'Tedda Tomney', '31 Arkansas Junction', '0220914982', '1972/09/20', '2009/06/04', 'F', 'ttomney47@springer.com', 'rU6\5qB3XxKZ''7', '2015/05/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV857867', 'Artemus Gloucester', '3419 Continental Road', '0085790971', '1981/02/22', '2005/08/01', 'F', 'agloucester48@github.io', 'vO4.zBpV+K\V9O', '2001/09/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV487204', 'Forrester Lorman', '8 Lighthouse Bay Point', '0870567961', '1957/05/04', '1979/05/24', 'F', 'florman49@chicagotribune.com', 'qO2_P>&5YGKie', '2006/01/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV075425', 'Berny Pafford', '272 Fordem Pass', '0743522027', '1980/10/17', '1968/01/25', 'F', 'bpafford4a@opera.com', 'uJ0/U_9T9"6p7bhm', '2012/11/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV539311', 'Matthew Smalley', '4 Dapin Avenue', '0158051749', '1973/04/02', '1978/08/07', 'M', 'msmalley4b@nih.gov', 'oV2@P.H1bJ4*$2a', '1986/10/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV636417', 'Laughton Rummery', '5054 Fair Oaks Crossing', '0737601778', '1974/09/30', '2021/03/27', 'M', 'lrummery4c@squarespace.com', 'qG9,X*Y9', '1976/01/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV540497', 'Bevin Seiller', '30609 Sugar Alley', '0528787221', '1953/12/20', '2004/06/05', 'F', 'bseiller4d@dot.gov', 'dJ5!8/6FvDbG`', '2004/12/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV240973', 'Gisela Cumberledge', '3 Annamark Park', '0839156879', '1975/03/21', '1989/07/03', 'F', 'gcumberledge4e@army.mil', 'xH6?suQh4GR>VvMS', '2016/02/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV033783', 'Melinde Carsberg', '95 Hanover Park', '0156462889', '1949/10/20', '1988/07/27', 'M', 'mcarsberg4f@baidu.com', 'rZ1}j6Kmq.<_r', '1975/06/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV899918', 'Nicholle Cholton', '15 Talmadge Trail', '0025452975', '1994/05/20', '1966/04/18', 'F', 'ncholton4g@nbcnews.com', 'yJ9{kJ(Km{q%W', '1985/11/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV806469', 'Randolf Rushbrooke', '69849 Trailsway Park', '0471646987', '1996/10/20', '1970/06/23', 'F', 'rrushbrooke4h@creativecommons.org', 'dD6|AFbY\yD=r', '1982/02/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV632248', 'Hendrick McConnel', '2076 Kennedy Crossing', '0580914685', '1997/10/13', '1967/01/17', 'F', 'hmcconnel4i@storify.com', 'sG4&?ysBo6ms', '1996/06/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV549543', 'Mella Casino', '9 Hazelcrest Street', '0000493512', '2005/03/22', '2002/06/27', 'F', 'mcasino4j@ameblo.jp', 'qU2.*l4DLFa\W', '1998/06/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV390694', 'Humfrey Golden', '9 Walton Point', '0567899813', '1984/12/03', '1967/06/14', 'M', 'hgolden4k@123-reg.co.uk', 'lL8+Qdc&xP5', '1974/09/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV125695', 'Barbara-anne Flucker', '487 Reinke Crossing', '0407000532', '1982/04/05', '1997/01/24', 'F', 'bflucker4l@zimbio.com', 'zQ9\e0dJ9VnX', '1973/06/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV319726', 'Kaine Crosson', '68 Golf Point', '0459389261', '1989/01/27', '2016/04/11', 'F', 'kcrosson4m@ovh.net', 'kV7$5oRz$u*mpnE', '2015/10/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV259903', 'Allie Hairsnape', '31 West Court', '0127752547', '1980/04/15', '1980/08/29', 'M', 'ahairsnape4n@mail.ru', 'bG3|Ze3+/V', '1999/01/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV704529', 'Gertruda Spaducci', '9 Harper Junction', '0559251743', '1998/08/19', '1983/04/07', 'M', 'gspaducci4o@craigslist.org', 'rK4*YQgArdB5.x7', '1980/12/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV698981', 'Adolphus Dunbobbin', '58 West Trail', '0645749495', '2005/12/17', '1981/09/06', 'M', 'adunbobbin4p@typepad.com', 'xV3)e641Z', '1995/08/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV692312', 'Fayre Simacek', '8979 Oxford Plaza', '0957971788', '1974/05/08', '1976/01/25', 'F', 'fsimacek4q@qq.com', 'qR8(ucDE', '1967/10/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV459139', 'Codie McJerrow', '06 Lighthouse Bay Junction', '0641668409', '1993/12/30', '1990/05/14', 'M', 'cmcjerrow4r@zdnet.com', 'cL5?.O+''/tGf{', '1994/08/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV966564', 'Reyna Trueman', '7045 Burning Wood Avenue', '0885312323', '1984/11/28', '1980/07/17', 'M', 'rtrueman4s@1688.com', 'rO0_R5d,#z&jkHIB', '2004/03/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV042409', 'Elicia Peart', '7 Elka Terrace', '0491782729', '1975/11/03', '1999/06/23', 'F', 'epeart4t@hugedomains.com', 'bK1)Zy<iNkP95R9W', '2000/07/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV950712', 'Alexandre Karpol', '803 Toban Hill', '0638918475', '2002/03/21', '2018/01/18', 'F', 'akarpol4u@icq.com', 'pJ0(k%?ZO\', '1992/11/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV300958', 'Babara Gwin', '0471 John Wall Point', '0407811107', '1973/10/05', '2017/04/11', 'M', 'bgwin4v@cargocollective.com', 'lV5#NgTMrvw', '2003/01/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV521642', 'Morganne Sabin', '8 Schlimgen Crossing', '0310204431', '1960/12/11', '1982/02/06', 'F', 'msabin4w@ehow.com', 'iA5/T@%_IX', '2007/12/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV775515', 'Daria Benettini', '2 Annamark Terrace', '0630424812', '1962/07/03', '1986/11/05', 'F', 'dbenettini4x@imgur.com', 'hX3}svvn', '1996/11/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV424840', 'Danya Pettman', '6348 Hauk Court', '0155091882', '1946/01/06', '2015/01/08', 'F', 'dpettman4y@gmpg.org', 'uV0+8NCwd514A', '1968/05/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV233868', 'Rubia Yersin', '236 Vernon Junction', '0281985795', '1990/12/01', '1975/04/27', 'M', 'ryersin4z@histats.com', 'eY6*%/kB', '1998/08/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV719279', 'Nada McCuis', '385 Prentice Circle', '0719802807', '1987/07/08', '1969/03/30', 'M', 'nmccuis50@blinklist.com', 'rQ7!,N,ytxv9H$Qi', '1977/06/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV024982', 'Janith Fitzsimon', '581 Sutteridge Parkway', '0858584963', '1953/02/02', '1979/06/27', 'F', 'jfitzsimon51@wikimedia.org', 'rG1$9}z&', '1984/05/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV784269', 'Zenia Oliveto', '56274 Barby Parkway', '0772685852', '1953/09/11', '2000/03/02', 'M', 'zoliveto52@blogs.com', 'iV1)%uI"', '1971/01/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV217564', 'Cinnamon Bergeon', '9508 8th Drive', '0142192285', '1992/08/30', '2017/07/05', 'M', 'cbergeon53@live.com', 'iO0?G1=lb4nui''cF', '2007/12/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV330261', 'Ogdan Asipenko', '80366 Autumn Leaf Avenue', '0759968637', '2005/12/25', '1996/12/29', 'F', 'oasipenko54@moonfruit.com', 'uW8"Q?Rys.', '2019/04/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV849707', 'Konrad Lakin', '27 Barby Circle', '0316544335', '1962/09/29', '1969/08/10', 'F', 'klakin55@ed.gov', 'xK1/CCKgA|tU', '1973/04/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV236940', 'Donni McLenahan', '75 Norway Maple Point', '0394559188', '1968/04/04', '2007/01/08', 'F', 'dmclenahan56@mozilla.com', 'sG3_F9tn', '1967/10/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV678331', 'Marcie Sisley', '5 Acker Lane', '0740476473', '1989/05/09', '1967/09/04', 'M', 'msisley57@pen.io', 'xC5=MG326JPp6K', '1999/02/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV978673', 'Xever Brookwell', '525 Eastwood Way', '0390914269', '1957/07/25', '2022/08/08', 'M', 'xbrookwell58@samsung.com', 'yM1"y*R<''N"Y,', '2006/04/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV582413', 'Fidela Dorning', '4294 Pepper Wood Terrace', '0572006959', '1961/03/14', '2021/07/21', 'M', 'fdorning59@yelp.com', 'uQ6$''hj.4e', '2015/07/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV095883', 'Alonzo Broderick', '5 Badeau Alley', '0159294175', '1963/02/03', '1967/02/15', 'M', 'abroderick5a@blog.com', 'zT7`8P+L9RXLQr', '1963/03/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV711681', 'Jarrad Obispo', '8141 Stephen Center', '0912457783', '1974/01/26', '2019/07/06', 'F', 'jobispo5b@netlog.com', 'uR2!EhZBdV/', '1995/05/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV098182', 'Lidia Wakerley', '017 Heath Way', '0453885840', '1958/11/20', '1972/06/15', 'M', 'lwakerley5c@issuu.com', 'dX7|yO7c', '2005/02/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV888660', 'Carla MacNair', '31972 Talmadge Road', '0334663970', '1949/03/17', '1975/08/05', 'F', 'cmacnair5d@bravesites.com', 'lT0}2j6w%`Z`', '1983/09/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV619323', 'Tobe Deakins', '52 Union Junction', '0375918333', '1987/03/15', '1978/06/09', 'M', 'tdeakins5e@google.com.au', 'iU2''16os', '2008/08/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV137998', 'Germaine Harkins', '03948 Scott Circle', '0641422001', '1949/02/18', '1968/08/24', 'M', 'gharkins5f@bloomberg.com', 'zJ2?fj6zW<', '1966/09/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV059671', 'Kim Heilds', '3 Northridge Parkway', '0212382811', '1968/07/28', '1974/07/06', 'M', 'kheilds5g@shareasale.com', 'wZ7`XZ8Y,iVie', '2022/03/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV193469', 'Ferdinanda Portingale', '209 Superior Terrace', '0894770878', '1974/04/30', '1975/09/13', 'F', 'fportingale5h@google.com.au', 'mS6@*Ha\/', '2011/10/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV533631', 'Bab Patriche', '34992 Jenifer Terrace', '0170294141', '1997/07/24', '2008/12/26', 'M', 'bpatriche5i@google.it', 'hY8@`Nn1zK', '1996/06/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV882439', 'Katie Critzen', '7 Rowland Junction', '0352826416', '1990/07/14', '1993/06/16', 'M', 'kcritzen5j@indiegogo.com', 'sV6$>Af01dy', '1967/09/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV322256', 'Broddy Kimbley', '92 Pine View Terrace', '0454686338', '1997/02/16', '1975/07/25', 'F', 'bkimbley5k@mysql.com', 'gM9}pYP(8W3>Zmy', '1978/08/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV691247', 'Curr O''Feeny', '74475 Sundown Way', '0873896514', '1996/06/04', '2017/06/12', 'M', 'cofeeny5l@example.com', 'iT3_g0h4wwQjI5@(', '1997/08/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV856226', 'Blayne McKeran', '35 Magdeline Alley', '0542040238', '1990/12/14', '1994/04/11', 'M', 'bmckeran5m@youtube.com', 'fU1*CF"L', '1998/05/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955353', 'Ludovika Sellar', '1853 Golden Leaf Alley', '0597346502', '1963/05/17', '1978/06/03', 'M', 'lsellar5n@nydailynews.com', 'dG2~*c&Q6k', '1974/05/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV350425', 'Dalila Ryle', '61 Algoma Road', '0680372888', '1992/04/11', '2020/06/30', 'F', 'dryle5o@nature.com', 'tJ3~qU$S$', '1980/01/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV161099', 'Thacher Daley', '2 Gale Circle', '0828762636', '1957/03/09', '1990/07/21', 'F', 'tdaley5p@ftc.gov', 'gZ9(@H%}(', '1995/05/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV394455', 'Frank Eddoes', '41 Arapahoe Way', '0363526946', '1992/04/10', '1967/04/03', 'F', 'feddoes5q@globo.com', 'uM3=8rMWVT', '2003/02/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV265849', 'Valaree Roselli', '232 Roxbury Trail', '0580686739', '1965/01/02', '2007/10/17', 'F', 'vroselli5r@canalblog.com', 'mH6@7EXz,Znk!vY1', '1974/01/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV537811', 'Mallorie FitzGibbon', '727 Comanche Center', '0240697810', '2004/07/22', '2001/10/29', 'F', 'mfitzgibbon5s@t-online.de', 'vM0=g''xmc''_%IIr', '2014/03/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV205866', 'Murvyn Lympany', '469 Eastwood Crossing', '0508719959', '1953/01/15', '1998/04/07', 'F', 'mlympany5t@springer.com', 'vY4(4=''Mj7f', '1985/11/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV477238', 'Sancho Pevreal', '96746 Golf Avenue', '0074110425', '1950/09/02', '1998/08/24', 'M', 'spevreal5u@stanford.edu', 'zY3%n6c3i.mkt\', '2022/07/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV077006', 'Vaughn Massinger', '5 4th Hill', '0845361410', '1950/12/13', '1975/04/06', 'M', 'vmassinger5v@cdbaby.com', 'eY2?FY,`', '1980/12/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV501947', 'Josey MacGuigan', '29 Northland Park', '0300375209', '2005/02/27', '1990/11/07', 'F', 'jmacguigan5w@hao123.com', 'gV8#LCIh', '1992/10/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV789814', 'Natalee Inge', '34498 Green Ridge Street', '0773978114', '1979/03/04', '2020/02/23', 'M', 'ninge5x@aol.com', 'iE9>j&~pb>~)', '1985/08/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV718785', 'Gaby Kuschek', '45 Haas Hill', '0486158049', '1990/11/29', '1978/11/02', 'F', 'gkuschek5y@bing.com', 'pB8}?(`bK', '2013/04/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV528843', 'Kary Kinneally', '1 Oak Junction', '0250487806', '1997/11/13', '1994/11/15', 'M', 'kkinneally5z@comsenz.com', 'sX7_1`YCl">', '1998/11/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV894856', 'Dale Essex', '461 Mitchell Lane', '0639572263', '1997/03/23', '1974/05/08', 'F', 'dessex60@usnews.com', 'wE8%k.E\@zcj>', '1994/01/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV422081', 'Lorens Bocock', '8355 Stone Corner Parkway', '0099881476', '1988/10/16', '1983/05/13', 'M', 'lbocock61@addthis.com', 'wA9*gH"X8f_4.H+', '1970/12/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV447108', 'Salli Levee', '584 Maple Wood Crossing', '0013593182', '1980/07/12', '2015/08/11', 'M', 'slevee62@psu.edu', 'dP8/ac`.Q8UO7', '2020/11/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV454412', 'Umeko Beauchamp', '4 Mayer Circle', '0985503101', '1959/07/28', '2002/11/16', 'F', 'ubeauchamp63@scientificamerican.com', 'bD1''Tzh?,', '2015/05/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV995948', 'Morgen Houdmont', '40346 Buena Vista Trail', '0403472075', '1977/11/08', '2018/03/24', 'F', 'mhoudmont64@bravesites.com', 'mP9}u!LeoL', '1973/04/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV063509', 'Gavin Checci', '141 Gale Trail', '0577678231', '1970/12/21', '2015/10/25', 'F', 'gchecci65@de.vu', 'bD9@5/>k(', '1974/01/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV277291', 'Melicent Janic', '5 American Terrace', '0833843519', '1954/03/24', '1965/09/20', 'M', 'mjanic66@gravatar.com', 'xU0,dGJ3)1>#KuC', '1977/08/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV189700', 'Randie Praundlin', '70848 Old Shore Way', '0165322449', '1976/09/18', '2006/09/03', 'F', 'rpraundlin67@indiegogo.com', 'dY8~\gREfAqd}usk', '1989/09/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV169905', 'Joyan Mettricke', '04105 Mendota Pass', '0649106031', '1974/06/23', '1981/10/27', 'M', 'jmettricke68@nasa.gov', 'cD4`+HZNI840l', '1976/12/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV949461', 'Dionysus Fearnside', '6 Thackeray Crossing', '0636728968', '1965/04/19', '1999/04/17', 'M', 'dfearnside69@bravesites.com', 'bS7*5RdATZP`GR', '1965/12/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV130878', 'Lindie Paal', '58452 Grayhawk Park', '0856364123', '1973/06/15', '1966/04/21', 'M', 'lpaal6a@multiply.com', 'qZ2*''F{1eFz&~5', '2019/12/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV867592', 'Courtnay Fireman', '7 Steensland Hill', '0602447201', '1981/04/05', '2021/06/16', 'F', 'cfireman6b@nsw.gov.au', 'vI2>}{Q(Ls`', '1972/03/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV552201', 'Iain Smiz', '1630 Burning Wood Pass', '0166165283', '1992/10/13', '1971/12/20', 'M', 'ismiz6c@ed.gov', 'jN8{6Ka\+lQic|U', '1978/09/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV172293', 'Tristam Varian', '74 Forster Pass', '0632651699', '1953/08/02', '1992/07/28', 'F', 'tvarian6d@ask.com', 'uD0{.K%Nz6Q', '1977/03/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV308774', 'Derron Fiander', '345 Center Crossing', '0532123764', '1959/01/20', '1979/07/14', 'M', 'dfiander6e@huffingtonpost.com', 'pZ4/g~aV', '1979/09/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV779637', 'Erina Duchenne', '655 Elka Street', '0227685032', '1989/02/06', '1966/12/24', 'F', 'educhenne6f@dropbox.com', 'fG4{''S\U=', '2018/07/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV201665', 'Donal Janaway', '4 Vermont Road', '0492401216', '1959/06/08', '2008/04/01', 'F', 'djanaway6g@forbes.com', 'oZ0,8jo)', '2016/04/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV850038', 'Elsinore Ambrosoni', '3 Maywood Pass', '0959362074', '1961/03/04', '1983/05/09', 'M', 'eambrosoni6h@ifeng.com', 'lJ9#N+AjCiqR', '2018/04/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV580990', 'Derry Le Port', '24 Troy Park', '0724719970', '1993/11/21', '1966/10/14', 'M', 'dle6i@archive.org', 'wK5"Aadit{2"', '2017/02/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV961275', 'Kaylil Coppenhall', '726 Bowman Circle', '0119724637', '1983/05/14', '1981/06/24', 'M', 'kcoppenhall6j@hao123.com', 'oG2.)4O.KQ', '1995/04/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV227248', 'Phylis Skillern', '35 Chinook Plaza', '0698660047', '2005/03/04', '1987/07/28', 'F', 'pskillern6k@intel.com', 'pE5.Oc24', '1994/02/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV605292', 'King Sarjeant', '8 West Park', '0747069927', '1997/11/30', '1991/09/06', 'F', 'ksarjeant6l@nsw.gov.au', 'vU1<Hr@$l', '1976/09/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV706415', 'Charmine Lathleiffure', '069 Johnson Circle', '0659492166', '1968/12/04', '1967/08/27', 'M', 'clathleiffure6m@last.fm', 'pG9@G7CHg<#Mlzp', '1970/02/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV736390', 'Coletta Orthmann', '53652 Red Cloud Pass', '0038175259', '1963/06/25', '2002/11/09', 'F', 'corthmann6n@naver.com', 'aK9$NbF$8/"fKqbA', '1986/02/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV851705', 'Ruthy Prayer', '2017 Barby Plaza', '0416961436', '1972/05/29', '1996/05/05', 'F', 'rprayer6o@abc.net.au', 'tT3}kVT.qim', '1979/05/31', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV048802', 'Vivianna Abdee', '83 Hudson Plaza', '0582552830', '1976/02/06', '2015/11/10', 'M', 'vabdee6p@unicef.org', 'rA1+Qe$`W7jf#H8', '2013/04/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV653866', 'Judi Rickcord', '54 Stone Corner Circle', '0965639292', '2003/01/02', '2004/12/10', 'F', 'jrickcord6q@example.com', 'rD8}B{tGY8Bj''Q', '1988/10/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV835274', 'Lane Lewzey', '13 Lakewood Gardens Pass', '0782691279', '1985/02/12', '1997/03/05', 'M', 'llewzey6r@umn.edu', 'cT3\RCN<#lW', '2004/01/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV242498', 'Lyndsey Roux', '4242 Oriole Parkway', '0520147788', '1975/10/21', '1979/08/11', 'F', 'lroux6s@alexa.com', 'sT0*ly=R*g~#h{?)', '2014/03/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV239920', 'Micheline Cuniffe', '60 Granby Street', '0512831176', '2002/05/11', '2000/02/25', 'M', 'mcuniffe6t@pen.io', 'rM0''v5y8', '1989/06/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV738399', 'Eldridge Ambroisin', '8507 Packers Street', '0179270375', '1951/08/15', '1982/06/27', 'F', 'eambroisin6u@bbc.co.uk', 'aK6?DAm,whK!', '1995/01/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV596246', 'Roman Haburne', '81780 Rutledge Parkway', '0973085296', '1957/12/01', '1979/08/02', 'F', 'rhaburne6v@vistaprint.com', 'yM7}1|H=', '2004/09/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV450177', 'Pattie Turfin', '2 Sutherland Crossing', '0939593568', '1965/12/16', '1975/06/28', 'M', 'pturfin6w@tmall.com', 'oM6|(I?%hK9}|!\', '1988/06/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV568902', 'Sylvia Spain-Gower', '9469 Gina Trail', '0062394314', '1950/06/04', '1985/05/30', 'F', 'sspaingower6x@360.cn', 'yJ2/tFh&RXIdw', '1999/11/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV964394', 'Lauri Van der Velden', '20 Bartelt Place', '0685033149', '1986/02/13', '1991/07/17', 'M', 'lvan6y@livejournal.com', 'yT1@AK~m2cf}sp', '1968/05/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV509726', 'Romola Seyler', '2 Sloan Lane', '0617346770', '1982/11/03', '1978/02/21', 'M', 'rseyler6z@biglobe.ne.jp', 'vY5/fWC6Dz0', '1988/02/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV044506', 'Brannon Vollam', '51 Morning Way', '0746562204', '1967/02/24', '1972/01/07', 'M', 'bvollam70@mediafire.com', 'tY4=`/ctTojV', '1989/01/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV265679', 'Georgy Labell', '7 Redwing Crossing', '0170227761', '1994/03/21', '2013/06/03', 'M', 'glabell71@phoca.cz', 'oP5%S@LBXg~mP', '1976/07/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV194953', 'Maitilde Gerbl', '6 Pennsylvania Street', '0821375853', '1959/05/11', '1988/10/02', 'M', 'mgerbl72@nbcnews.com', 'hW7&(%w<~', '1984/08/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV764161', 'Gena Heninghem', '29 Onsgard Trail', '0737986204', '1982/03/28', '1979/08/14', 'M', 'gheninghem73@odnoklassniki.ru', 'zM5_{UTVf),', '1965/10/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV475945', 'Fredek Kirkness', '602 Blue Bill Park Lane', '0624733011', '1965/08/01', '2000/11/17', 'F', 'fkirkness74@webmd.com', 'mP7<YXESYjdl?"M6', '1974/01/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV068235', 'Mia Kettleson', '3030 Prentice Road', '0440563515', '1979/04/21', '1992/03/02', 'F', 'mkettleson75@exblog.jp', 'qU2?FN0L6WA', '2015/07/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV343692', 'Kin Brosius', '02 Waxwing Crossing', '0617541461', '1961/10/30', '1964/10/11', 'M', 'kbrosius76@engadget.com', 'sB7#axesb*', '2013/08/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV414451', 'Irina Brade', '1579 Gina Terrace', '0130953412', '1969/09/21', '2000/02/14', 'F', 'ibrade77@facebook.com', 'lX7`RlANbX&jL,', '1973/05/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV078937', 'Scottie McGifford', '468 Muir Point', '0621268092', '1953/11/21', '1966/03/06', 'F', 'smcgifford78@livejournal.com', 'rY2+j''|1', '2004/01/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV941014', 'Minny Deyes', '2 Fallview Park', '0090986365', '1981/04/21', '1993/01/22', 'M', 'mdeyes79@jigsy.com', 'oQ1!v8Pme$@i)YT', '2016/07/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV019077', 'Ford Dewey', '3 Straubel Park', '0616334311', '1994/12/12', '1996/08/25', 'M', 'fdewey7a@printfriendly.com', 'lD9,0_S3', '2012/10/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV878169', 'Sigfried Kobera', '25 Gina Crossing', '0658605480', '1956/03/09', '2010/08/16', 'M', 'skobera7b@myspace.com', 'xS2=\02%sbuM', '1972/07/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV013506', 'Mame Suerz', '02669 Green Ridge Street', '0874079524', '2001/10/24', '1978/09/04', 'M', 'msuerz7c@chron.com', 'nM4|1cc"', '2004/07/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV481500', 'Gerta Povlsen', '8685 Logan Drive', '0646035780', '1953/08/08', '1969/10/15', 'F', 'gpovlsen7d@fc2.com', 'bE7/vuj(lew', '1991/06/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV303894', 'Christian Faulconer', '10 Doe Crossing Road', '0966976836', '1950/08/31', '2002/01/17', 'F', 'cfaulconer7e@sfgate.com', 'fN8&i?OH$\@H', '2004/07/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV317833', 'Nikolos Draysey', '42 Sheridan Road', '0376060475', '1967/06/26', '1998/03/12', 'F', 'ndraysey7f@spiegel.de', 'fY6`8RTAU''D', '1973/02/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV372709', 'Rianon Noulton', '420 Huxley Parkway', '0758922662', '1972/11/05', '1978/02/12', 'M', 'rnoulton7g@e-recht24.de', 'rK6`Bct>D0Q7gx', '1999/01/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV196736', 'Stan Spurret', '4 Village Green Junction', '0675615877', '1951/04/22', '2004/12/10', 'F', 'sspurret7h@goo.ne.jp', 'rZ1<1=t.jtCbe', '2017/06/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV804633', 'Brian Withey', '1158 Farwell Hill', '0227540405', '1989/12/03', '2006/07/04', 'M', 'bwithey7i@mit.edu', 'mI9>Jt,)3w#', '1992/08/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV440681', 'Alana Buesden', '21 Thompson Alley', '0903388398', '1997/11/14', '2022/12/02', 'M', 'abuesden7j@nhs.uk', 'eU8+~l{L2', '1977/08/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV158614', 'Deerdre Spitaro', '6 Hazelcrest Lane', '0103922383', '1958/06/29', '1984/04/15', 'F', 'dspitaro7k@dion.ne.jp', 'oF8(s*W`', '2006/10/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV415066', 'Gelya Girardeau', '4 Acker Hill', '0881455438', '2002/07/02', '1978/03/14', 'F', 'ggirardeau7l@uiuc.edu', 'nX2_xX,JI0(\6%`', '1994/07/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV213110', 'Gayle Basill', '4449 Cottonwood Drive', '0880577984', '1964/08/28', '2017/01/19', 'F', 'gbasill7m@topsy.com', 'zC2"oo*zkCg', '1981/04/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV717819', 'Jackelyn Mottershaw', '86 Elgar Avenue', '0966845207', '1996/03/01', '1997/09/05', 'M', 'jmottershaw7n@dailymail.co.uk', 'hO8\rHLWRgctM', '2016/09/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV496066', 'Vergil Fraulo', '7 East Place', '0504605990', '1970/06/18', '1979/07/06', 'M', 'vfraulo7o@live.com', 'mB7)"yn,6hZeyB', '2017/11/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV813687', 'Ericha Tearney', '75716 Monterey Trail', '0551763297', '1946/03/09', '2017/02/23', 'F', 'etearney7p@artisteer.com', 'lL9)MWnc9rH>', '1977/06/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV648987', 'Nancie Medcraft', '5 Swallow Terrace', '0994955536', '1994/02/04', '1965/08/28', 'M', 'nmedcraft7q@state.gov', 'hO2?V&55O"+I,H0', '2022/12/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV415188', 'Dede Doughartie', '6 Doe Crossing Circle', '0277974141', '1950/11/12', '1969/12/04', 'M', 'ddoughartie7r@wikimedia.org', 'zQ0)oiVQX', '1967/02/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV768035', 'Rod Reolfi', '6 Lotheville Plaza', '0462408215', '1987/12/08', '2019/11/06', 'F', 'rreolfi7s@yellowbook.com', 'uF3!{tylI''.r,+', '1974/03/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV383849', 'Dino Porcas', '47960 Butterfield Pass', '0024561074', '1951/05/29', '1999/04/20', 'M', 'dporcas7t@go.com', 'uY9%fC<in', '2016/01/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV429712', 'Weider Brizland', '553 Almo Park', '0497202651', '1949/12/21', '1994/08/17', 'M', 'wbrizland7u@washingtonpost.com', 'mM7(MGz9B8L6BE', '2015/10/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV336097', 'Guy Raffan', '2 Petterle Circle', '0171979814', '1971/05/10', '2015/12/18', 'F', 'graffan7v@wufoo.com', 'pX7|4KhD', '1964/11/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV271794', 'Shirlene Meads', '3 Katie Crossing', '0160165707', '1977/09/09', '1988/08/10', 'M', 'smeads7w@msn.com', 'aQ5(exe6q', '2002/04/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV581657', 'Cchaddie Cockerill', '54935 Graedel Alley', '0414405846', '1989/06/02', '1965/07/24', 'F', 'ccockerill7x@slideshare.net', 'jO7<e(Z(`0ip', '2010/12/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV371771', 'Maddy Casel', '9425 8th Park', '0030000350', '2004/04/21', '1983/06/23', 'M', 'mcasel7y@mtv.com', 'zH7/Bil8VM', '1964/11/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV849197', 'Sada Cresar', '3 Hoepker Junction', '0892258745', '1983/07/15', '2020/01/02', 'M', 'scresar7z@uol.com.br', 'oJ2)$2%{F0lE', '2021/04/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV946657', 'Maia Haskett', '8225 Warrior Alley', '0483972258', '1954/11/26', '2006/07/30', 'F', 'mhaskett80@amazon.co.jp', 'tS5''tbe"I#Yz|ag', '2010/02/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV310820', 'Margaux Lambkin', '6 Arapahoe Trail', '0851611982', '1992/05/27', '1984/05/21', 'M', 'mlambkin81@last.fm', 'wO8*xHm\3', '1986/01/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV801219', 'North Nobles', '1741 Amoth Place', '0067058967', '1946/05/08', '2007/04/16', 'F', 'nnobles82@diigo.com', 'fU1.$o6z2NM@1', '2002/10/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV579268', 'Fionnula Pack', '66599 Oak Crossing', '0030291619', '1963/03/06', '1978/11/26', 'F', 'fpack83@bravesites.com', 'jG6}PUD_+O', '2003/06/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV325416', 'Jaclin Mehaffey', '42890 Browning Drive', '0119837575', '1963/12/01', '1977/05/21', 'F', 'jmehaffey84@technorati.com', 'mK8/|#DJgrQ4(', '1977/11/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV408057', 'Hymie Bostock', '01407 Lake View Terrace', '0108529206', '1974/11/21', '1977/09/04', 'F', 'hbostock85@hud.gov', 'uN5*lPEG"JY3}EsE', '1989/12/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV349566', 'Forest Awin', '0 Schlimgen Park', '0925897554', '2000/08/09', '1983/01/06', 'F', 'fawin86@yahoo.co.jp', 'vW7|`a?%)I', '1998/04/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV659630', 'Vally Swatradge', '44896 Delaware Junction', '0178625718', '1994/03/29', '2008/04/17', 'M', 'vswatradge87@bloglovin.com', 'zB9%oU{RD', '1992/07/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV834735', 'Dorena Michele', '7 Leroy Drive', '0558123260', '1970/12/11', '2018/12/25', 'M', 'dmichele88@pinterest.com', 'nR4!J_0b%', '1993/12/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV894914', 'Anetta Dering', '62 Beilfuss Center', '0835734952', '1972/08/17', '1973/05/24', 'M', 'adering89@netlog.com', 'tJ7(@b%E,~)oWk', '1978/03/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV724440', 'Yul Parsons', '7 Warbler Pass', '0753124115', '1974/08/07', '2022/01/24', 'M', 'yparsons8a@constantcontact.com', 'dV5#rknjZIzKZ', '2003/08/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV160815', 'Saxon Christopher', '3970 Clyde Gallagher Way', '0746869892', '1964/05/18', '1978/01/05', 'M', 'schristopher8b@boston.com', 'yY3">@LQrbM+_m*Y', '2022/12/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV281921', 'Carling Charlet', '3128 Sachs Place', '0180957537', '1953/12/07', '1980/04/26', 'F', 'ccharlet8c@w3.org', 'kR4(qUB0Ukl', '2002/08/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV426395', 'Rahal Rossoni', '5 Welch Crossing', '0318974110', '1956/07/22', '2019/02/13', 'M', 'rrossoni8d@meetup.com', 'hG0?&r@H', '2008/05/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV502918', 'Sher Ros', '346 Kings Drive', '0300533390', '1976/03/02', '1964/07/02', 'F', 'sros8e@ft.com', 'xH4`"hGi//', '2000/03/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV432339', 'Adam Crosbie', '2 Shelley Junction', '0446378064', '1982/12/01', '1976/02/07', 'F', 'acrosbie8f@dmoz.org', 'lR8{d6/bH*#C', '2011/02/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV178790', 'Cindra Midgley', '7190 Arapahoe Court', '0256572120', '1976/08/11', '2011/10/10', 'M', 'cmidgley8g@biglobe.ne.jp', 'zW7=dP*/G3JAsZ>p', '1984/01/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV987466', 'Paola Gierke', '556 8th Center', '0544030832', '1982/02/19', '2021/01/22', 'M', 'pgierke8h@baidu.com', 'sJ4}rNeOFwLz', '2008/08/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV923867', 'Carter Bridgland', '363 Lake View Avenue', '0619369191', '1959/08/01', '2020/09/14', 'F', 'cbridgland8i@wix.com', 'yA8<3ov4X}HmB', '2013/12/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV288477', 'Benni Folbigg', '708 Golf Pass', '0123623271', '1995/12/31', '1974/10/18', 'M', 'bfolbigg8j@google.fr', 'xP3_11o6j"', '2016/06/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV047107', 'Erhard Gibbings', '22409 Homewood Way', '0112860662', '1985/11/16', '1987/01/22', 'F', 'egibbings8k@bloomberg.com', 'kR7@)9P(MM*}Y6d', '2008/06/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV092108', 'Noni Spilisy', '76882 Lindbergh Trail', '0794517380', '1959/05/26', '1998/06/09', 'F', 'nspilisy8l@bbc.co.uk', 'oD4,>ZtG1={i', '2012/05/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV611945', 'Sela Pheby', '62908 Marquette Way', '0757622364', '1958/02/07', '1988/06/18', 'F', 'spheby8m@weibo.com', 'iR7_@}>W', '1974/11/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV828328', 'Oralie Bilton', '6 Cardinal Drive', '0649055985', '1979/08/05', '1997/12/12', 'F', 'obilton8n@flavors.me', 'pL2"JD)o,yB', '1986/07/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV487507', 'Dagmar O''Farris', '70 Columbus Way', '0257288157', '1964/01/26', '2011/03/22', 'F', 'dofarris8o@auda.org.au', 'dD2*l{1n*yAqKFgQ', '1973/09/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV137686', 'Alie Wigsell', '3 Bayside Circle', '0281633014', '1981/02/25', '1997/05/17', 'F', 'awigsell8p@smh.com.au', 'dV1*D`tkd#XYIb?', '1969/10/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV189822', 'Karrie Creighton', '1 Vermont Street', '0498348911', '1969/02/13', '1999/01/11', 'M', 'kcreighton8q@theatlantic.com', 'yM9"Vj!4', '2006/08/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV948316', 'Joceline Arnoll', '79665 Stone Corner Junction', '0367186083', '1949/01/23', '1973/11/19', 'M', 'jarnoll8r@dion.ne.jp', 'tT7&&#{3z7=GZ', '1970/06/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV832513', 'Daria Gendrich', '24933 Charing Cross Center', '0006100721', '2002/12/08', '2023/12/16', 'M', 'dgendrich8s@nydailynews.com', 'nQ4$Ub''NC', '2017/08/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV325731', 'Kippie MacInerney', '1 Derek Junction', '0839087201', '2003/07/31', '1968/11/12', 'M', 'kmacinerney8t@wunderground.com', 'hY2&#I|&/SBk!xH', '1980/07/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV730049', 'Jodie Manicom', '87 Michigan Parkway', '0781589140', '1970/04/24', '1963/03/02', 'M', 'jmanicom8u@about.me', 'hA2&i<m=!g|>5', '1980/02/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV976250', 'Nikolia Pardal', '26575 Nova Way', '0605246924', '2004/07/26', '2005/07/14', 'F', 'npardal8v@wp.com', 'rW3+(fUd_k~', '1995/10/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV082912', 'Gustavo Battelle', '38508 Saint Paul Plaza', '0790177407', '1969/12/07', '1990/04/30', 'F', 'gbattelle8w@shareasale.com', 'sG6$6AS@', '2022/05/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV324481', 'Dilan Matignon', '844 Independence Avenue', '0186360697', '1965/11/10', '1996/04/07', 'M', 'dmatignon8x@sciencedaily.com', 'eV6<8w`v2', '1984/06/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV010574', 'Raf Westoll', '16 Anthes Avenue', '0641489143', '1947/10/13', '1964/07/28', 'F', 'rwestoll8y@vkontakte.ru', 'uZ5\9''.{S9}h!', '1975/07/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV500254', 'Helenelizabeth Rhubottom', '0277 Center Alley', '0180669567', '2003/04/08', '1997/08/11', 'F', 'hrhubottom8z@go.com', 'aR9\Q+bX!&"nX', '2004/08/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV979641', 'Manon Layfield', '30 Bobwhite Hill', '0490165757', '1967/06/21', '1986/04/20', 'M', 'mlayfield90@ifeng.com', 'bM9#HS)5m', '1992/01/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV732368', 'Adel Perrins', '8663 Pearson Hill', '0287216536', '1963/07/27', '1965/07/22', 'M', 'aperrins91@fda.gov', 'qJ4\=+=SO.}51', '1992/12/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV250123', 'Babita Franceschelli', '68414 Sommers Hill', '0344293228', '2004/12/31', '2004/12/31', 'M', 'bfranceschelli92@ning.com', 'qW3|\aGblgOWaO', '2017/04/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV171133', 'Celisse Warrior', '6151 Drewry Hill', '0415731230', '1987/06/28', '1968/06/23', 'F', 'cwarrior93@godaddy.com', 'dF3`e}(~cT|oGKlE', '1986/11/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV592137', 'Fonsie McElmurray', '42 Bellgrove Trail', '0331117995', '1958/07/05', '1965/01/24', 'M', 'fmcelmurray94@360.cn', 'wC8><mAR', '1972/02/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV650538', 'Mellisent Juliano', '241 Carberry Alley', '0545573874', '1948/06/01', '1971/06/03', 'M', 'mjuliano95@fda.gov', 'hA4"s!X"?X}r"~', '1990/03/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV111555', 'Patti Riddich', '780 Michigan Drive', '0773573204', '1986/09/13', '1972/09/14', 'F', 'priddich96@businesswire.com', 'dR8''zzfQ%XU', '2011/01/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV836655', 'Mahmoud Dunklee', '81 Northfield Drive', '0448405925', '2002/01/16', '1984/03/28', 'F', 'mdunklee97@bbb.org', 'wF9/N1MVcD=,p8o"', '1969/06/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV548260', 'Minnnie Pencot', '9 6th Parkway', '0971398084', '1993/06/18', '2023/04/10', 'F', 'mpencot98@mozilla.com', 'mO6+s|I@p_*SJN', '1995/12/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV724589', 'Suki Goaks', '6 Corscot Street', '0153070110', '1955/12/06', '2017/05/01', 'F', 'sgoaks99@flickr.com', 'pA2<FBH7', '1979/06/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV905823', 'Norbie Ciric', '5 Warner Circle', '0185620939', '1946/12/19', '1971/12/20', 'F', 'nciric9a@amazon.co.uk', 'zS9_gi(VVb|+3', '2015/09/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV142677', 'Gracie Extance', '94672 Sachs Place', '0623681208', '1985/09/10', '1979/12/03', 'M', 'gextance9b@google.cn', 'dJ4)}l.PH%$>F', '1984/07/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV823703', 'Koressa Fiddymont', '6 Birchwood Place', '0642845752', '1965/01/12', '1988/04/12', 'M', 'kfiddymont9c@engadget.com', 'oH2&}dw)Z+b', '1968/01/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV740277', 'Cody Mordaunt', '01760 Novick Pass', '0326585276', '1951/11/12', '1974/12/08', 'M', 'cmordaunt9d@google.com.br', 'dM6#n0$0b3O_##', '1984/07/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV247423', 'Elise Artinstall', '00646 Hagan Terrace', '0918696354', '1957/02/03', '2024/06/04', 'M', 'eartinstall9e@weibo.com', 'xV6%(?J}X4S', '1980/08/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV512330', 'Demetre Dutson', '554 Maywood Drive', '0623543111', '1998/03/04', '1990/10/27', 'F', 'ddutson9f@liveinternet.ru', 'aY7"wNGceD&E', '1990/01/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV843982', 'Niki Finlason', '3 Cody Crossing', '0867612659', '1952/10/28', '1972/12/28', 'F', 'nfinlason9g@google.de', 'sV6?I/Gg,', '1967/12/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV701194', 'Donavon Krinks', '4 Randy Avenue', '0503113962', '1997/01/17', '2001/11/08', 'M', 'dkrinks9h@theguardian.com', 'pR3+''_0d}$)HNm', '1999/12/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV601678', 'Geri Claffey', '595 Ridge Oak Pass', '0512406028', '2001/09/06', '1980/01/10', 'F', 'gclaffey9i@cnbc.com', 'vC0%2Y3WTl(IN(', '1994/09/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV468800', 'Teressa Boriston', '444 David Pass', '0212681317', '1949/01/03', '1994/12/30', 'M', 'tboriston9j@bandcamp.com', 'iF5(o=HKP()', '1986/06/19', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV988432', 'Der Eyers', '6 Sundown Terrace', '0616751341', '1987/11/11', '1984/12/09', 'M', 'deyers9k@youtube.com', 'pI7{v2~V''M}', '2006/05/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV702830', 'Lawton Fitter', '65 Moland Alley', '0885632270', '1985/03/01', '1968/04/16', 'F', 'lfitter9l@quantcast.com', 'eN3,fQB>''\U\7', '1996/05/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV540027', 'Udell Impett', '07 Corscot Place', '0479805150', '2000/05/30', '1976/01/23', 'M', 'uimpett9m@flavors.me', 'bQ6{SR)qsDlg', '1973/09/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV185852', 'Auguste Widdocks', '26 Bartillon Junction', '0278777239', '1971/08/06', '2001/08/10', 'M', 'awiddocks9n@fc2.com', 'iK6.MyKl''t+n', '1986/10/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV796942', 'Yvonne Divis', '99191 Randy Point', '0721652724', '2004/04/09', '1974/04/15', 'M', 'ydivis9o@cpanel.net', 'oP8\|sEkQ+=pR$`c', '1972/04/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV825924', 'Coral Rotham', '0069 Loftsgordon Parkway', '0436478262', '1957/01/22', '2017/08/19', 'F', 'crotham9p@nih.gov', 'dS6|OQkc(GZS', '1972/07/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV327962', 'Stephan Bortoluzzi', '8194 Iowa Alley', '0316881272', '1990/04/27', '1993/01/20', 'M', 'sbortoluzzi9q@reddit.com', 'aE2''=EX"dV', '1983/12/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV140794', 'Stevy Berzen', '997 Melvin Place', '0150490274', '1953/11/16', '2014/10/21', 'M', 'sberzen9r@uiuc.edu', 'yP9(7n|~f', '1971/04/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV126722', 'Cort Fear', '07 Moland Pass', '0611559522', '1983/10/03', '1965/03/28', 'M', 'cfear9s@fema.gov', 'wD3(_U<_$8N', '2000/08/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV105572', 'Ardine Eastway', '86454 Briar Crest Terrace', '0378798984', '2005/06/25', '2023/06/23', 'F', 'aeastway9t@issuu.com', 'dA4~j\X@~JIC', '2022/01/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV289904', 'Lorin Smorthwaite', '0 Nova Terrace', '0897880447', '1979/08/16', '1985/07/18', 'F', 'lsmorthwaite9u@ucsd.edu', 'qI8>KIN(d0u?!F', '2015/11/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV905989', 'Hestia Joblin', '52 Fisk Pass', '0427161873', '1984/04/15', '1978/12/28', 'F', 'hjoblin9v@ameblo.jp', 'eK4.kZ*q/b,', '1989/03/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV007654', 'Alvin Whatley', '40 Katie Street', '0237504566', '1986/06/28', '2018/03/09', 'F', 'awhatley9w@mediafire.com', 'nR6@#V/+', '2010/10/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV058160', 'Inger Veschambes', '14180 Helena Street', '0884500428', '2004/12/07', '1989/04/11', 'F', 'iveschambes9x@ucsd.edu', 'tD4|w/#<}8fiY', '2023/02/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV481342', 'Genna Filoniere', '4209 Merry Court', '0359462992', '1971/04/30', '1967/01/26', 'F', 'gfiloniere9y@friendfeed.com', 'fW0#7n?dnClq3!', '2021/11/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV922479', 'Rogers Greathead', '387 Hoepker Point', '0294628831', '2003/02/26', '2022/12/27', 'M', 'rgreathead9z@amazonaws.com', 'gL3>Jz$Fl', '1971/06/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV307042', 'Lindy MacKenzie', '29039 Vermont Terrace', '0381448052', '2004/02/21', '1980/01/17', 'M', 'lmackenziea0@ted.com', 'kB5>JWvwnx', '2007/08/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV516612', 'Aldwin Abilowitz', '1217 Sunbrook Drive', '0652885412', '1982/11/18', '1969/01/11', 'F', 'aabilowitza1@nymag.com', 'eC6''a''jJd9K9', '2003/04/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV495945', 'Joby Hartop', '0980 Morning Place', '0537503889', '1951/06/12', '2022/08/30', 'F', 'jhartopa2@guardian.co.uk', 'qH7{+wV=kL', '1977/12/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV823417', 'Julio Matches', '838 Declaration Center', '0427542270', '1989/11/08', '2021/05/25', 'M', 'jmatchesa3@archive.org', 'jD1`+Fux!=', '2001/10/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV301601', 'Gabriel Spatarul', '2613 Chinook Parkway', '0073646142', '1978/08/11', '2019/04/16', 'F', 'gspatarula4@pbs.org', 'hY5,.Pyp`Ua>', '2014/12/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV900198', 'Yuma Dignan', '6 Fisk Park', '0738483605', '2001/03/29', '1991/09/30', 'F', 'ydignana5@wufoo.com', 'uX3%>SnjoQ?P+', '2014/07/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV469574', 'Shantee Privost', '28629 Stang Way', '0213065737', '1960/12/12', '1985/07/13', 'F', 'sprivosta6@state.gov', 'zV6@"TpjB', '1971/09/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV069985', 'Lemar Kohlerman', '560 Ruskin Parkway', '0278232960', '2001/05/26', '1970/01/19', 'M', 'lkohlermana7@netlog.com', 'uD9?thMp=2', '1994/02/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV276433', 'Goddart Yorke', '5 Prentice Hill', '0849959526', '1997/03/19', '1977/08/01', 'F', 'gyorkea8@ustream.tv', 'fY7.@sp"iCqsVo', '1985/08/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV542204', 'Darin Grisedale', '24 Forest Run Road', '0326791345', '1962/09/13', '1999/08/06', 'F', 'dgrisedalea9@nytimes.com', 'dZ4?r5Y_ua', '1965/11/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV658780', 'Allissa Merrett', '65 Cody Road', '0709957366', '1993/04/06', '1967/12/07', 'F', 'amerrettaa@mediafire.com', 'qP2}N&yK`fZ<Z&', '2011/10/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV662711', 'Donelle Ternott', '6 Annamark Court', '0785428332', '1964/12/20', '1998/08/28', 'F', 'dternottab@trellian.com', 'cY8<$ZYV6kaQ', '1972/01/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV611249', 'Gayle Guwer', '5067 Golf View Parkway', '0328504553', '1957/10/17', '1999/08/22', 'F', 'gguwerac@squidoo.com', 'pJ2`$d,ZQ{e/fB|', '1995/07/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV248216', 'Alejandro Pullen', '71 Hooker Parkway', '0484514500', '1961/07/24', '2009/02/03', 'F', 'apullenad@paypal.com', 'hQ1/@1ced', '1987/03/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV454466', 'Dmitri Alleburton', '26 Main Crossing', '0758248339', '1968/11/11', '2020/01/17', 'F', 'dalleburtonae@sakura.ne.jp', 'kC2)`{0Z|yI8\q', '1966/10/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV228899', 'Des Mitchenson', '147 Lakewood Terrace', '0640385638', '1996/05/11', '1987/01/16', 'M', 'dmitchensonaf@diigo.com', 'jF7\%"Dm0t"</W{}', '1976/10/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV240042', 'Jeanie Son', '66 Dahle Avenue', '0577816195', '1977/12/07', '1996/10/11', 'M', 'jsonag@businesswire.com', 'vR0?$h|qU', '1968/05/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV589075', 'Luella Coan', '3 Sauthoff Center', '0779683581', '1945/08/24', '2017/08/09', 'F', 'lcoanah@yellowpages.com', 'lE2/@yvX3yg', '2004/08/31', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV305995', 'Gerta Hitzschke', '12724 Stone Corner Point', '0499702879', '1951/03/30', '2022/01/11', 'M', 'ghitzschkeai@europa.eu', 'iY6=Z&9<u$.yO/', '1991/11/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV321111', 'Tully Seniour', '2 Dwight Drive', '0939757566', '1964/04/01', '2005/03/08', 'M', 'tseniouraj@ca.gov', 'pJ8\tB1X\G', '1988/02/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV034657', 'Gaye Espinay', '86528 Schlimgen Parkway', '0297379052', '2002/04/03', '2022/05/02', 'F', 'gespinayak@mail.ru', 'cD1@!=vRZT$h', '2006/10/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV982608', 'Tanney Stiffell', '708 Barby Junction', '0914353034', '1999/12/22', '2022/12/12', 'F', 'tstiffellal@delicious.com', 'mZ8"N=NI.oKQy=7', '1997/09/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV958308', 'Bridgette Sherland', '5780 Hudson Place', '0383724574', '1960/02/28', '1983/01/07', 'F', 'bsherlandam@rambler.ru', 'iB5)P7JLbDtr%58}', '1972/03/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV574049', 'Fraser Fountain', '38 Vidon Place', '0477195533', '1947/06/14', '1995/03/07', 'M', 'ffountainan@xrea.com', 'eH8&~zEUj', '2017/01/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV573727', 'Marcelline Barth', '91 Iowa Road', '0650645851', '1959/03/23', '1963/04/15', 'F', 'mbarthao@elegantthemes.com', 'mE4/DilmC.Q', '2014/01/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV369260', 'Gaven Behling', '49853 Sycamore Pass', '0783191081', '1978/10/10', '2003/12/31', 'F', 'gbehlingap@bbb.org', 'oK4}{Yzht', '2003/04/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV841814', 'Esmaria Cromar', '675 Daystar Alley', '0617858522', '1988/01/05', '1990/03/16', 'F', 'ecromaraq@intel.com', 'pY9&\PkV', '1987/05/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV904699', 'Jacklin Bushaway', '117 Norway Maple Street', '0024811172', '1970/10/18', '2011/12/05', 'M', 'jbushawayar@addtoany.com', 'hY6@xF`6{yA2@w6', '1991/09/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV589672', 'Tanny Ferrarini', '76527 Dakota Way', '0973987714', '2004/03/17', '2011/06/29', 'F', 'tferrarinias@vk.com', 'lD4(z|}/_l', '1982/02/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV725320', 'Stephan Platts', '8093 Rockefeller Terrace', '0865853607', '1981/12/25', '1980/03/03', 'M', 'splattsat@dion.ne.jp', 'rA3@=z{3Y=x~}9~E', '2021/11/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV099000', 'Ardyth Eastham', '48546 Memorial Hill', '0158815622', '1978/10/02', '1967/04/14', 'F', 'aeasthamau@microsoft.com', 'sI7*/djwqg', '2006/07/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV392010', 'Rurik Priel', '28320 Talisman Way', '0878840118', '1985/03/24', '1997/03/17', 'F', 'rprielav@typepad.com', 'nX4)aQ0f4j_b`0', '2019/03/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV429379', 'Wait Brunelli', '198 Bunting Pass', '0387138285', '1974/01/17', '2021/02/26', 'F', 'wbrunelliaw@buzzfeed.com', 'hE3(,>a?HhuWOhR', '1988/02/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV231149', 'Hunt Wynter', '92 Ilene Circle', '0472853658', '1949/04/12', '2001/05/10', 'F', 'hwynterax@microsoft.com', 'mJ6|VK@9M"R|', '1974/08/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV916597', 'Hildy Flemmich', '4392 Mendota Street', '0219030076', '1972/09/13', '1989/11/03', 'F', 'hflemmichay@vkontakte.ru', 'aL1>_*}MIk.4', '1973/10/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV688246', 'Lesya Ferro', '24 Mayfield Alley', '0792248585', '1952/05/10', '2015/01/03', 'F', 'lferroaz@hostgator.com', 'kJ7,0s?ZdDV', '1999/08/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV232166', 'Livvy Kornas', '5 Linden Way', '0086325861', '2002/04/12', '1968/12/04', 'M', 'lkornasb0@youtu.be', 'xE3&%(QHm', '2002/02/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV302491', 'Peria Brayne', '35 Welch Crossing', '0767197101', '1976/10/08', '1963/09/02', 'F', 'pbrayneb1@1688.com', 'xC5@gQ8&', '1987/08/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV509338', 'Terri Tosdevin', '5468 Declaration Park', '0005796261', '1954/04/29', '2006/11/12', 'M', 'ttosdevinb2@seattletimes.com', 'qX7&V4nq>jzsueiJ', '1985/07/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV297438', 'Mercie Poppleston', '6234 Dryden Place', '0923163354', '1947/04/16', '1971/09/24', 'M', 'mpopplestonb3@techcrunch.com', 'jZ3_nFOYVK*JL8r#', '1972/04/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV259787', 'Angeline Cohalan', '05 Westerfield Circle', '0049297489', '1966/06/09', '1973/12/15', 'M', 'acohalanb4@cam.ac.uk', 'aF4>w15ZSFIInef', '1966/01/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV224828', 'Vina Wickendon', '0823 Jackson Point', '0729319632', '1991/01/20', '1969/06/30', 'F', 'vwickendonb5@indiegogo.com', 'uT9_7uNaWgdZ', '1972/10/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV340941', 'Kelsi Russell', '240 Goodland Court', '0454062370', '1972/11/29', '1983/06/27', 'F', 'krussellb6@examiner.com', 'vH2`S/''ZQ61wVO', '1988/03/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV356937', 'Barbie Balaam', '128 Ilene Pass', '0090391054', '1993/11/06', '2008/09/12', 'M', 'bbalaamb7@networksolutions.com', 'aX3|J$O"', '1968/12/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV014060', 'Ardis Tomczynski', '68 Fairfield Circle', '0190979302', '1949/12/26', '2020/11/06', 'M', 'atomczynskib8@whitehouse.gov', 'uJ0>''dG"o', '1989/05/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV453523', 'Ingamar Aberkirder', '67631 Crest Line Place', '0305220605', '1966/05/27', '1996/07/19', 'F', 'iaberkirderb9@scientificamerican.com', 'sA6<+M|U`n', '2015/01/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV950802', 'Beatriz Roskam', '4 Loftsgordon Plaza', '0755537665', '1986/11/12', '1988/01/06', 'F', 'broskamba@apple.com', 'nI1#U"mt', '2012/08/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV178173', 'Madison Linning', '813 Hoard Road', '0164673266', '1947/10/09', '1976/11/11', 'F', 'mlinningbb@ucoz.com', 'lY2?vyu9', '2021/01/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV953475', 'Roseanne Grinishin', '80 Shopko Court', '0532470399', '1971/12/15', '2019/04/13', 'F', 'rgrinishinbc@huffingtonpost.com', 'tZ8\o?p/0zcy', '2006/03/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV180911', 'Kerk Brahm', '41789 Lake View Parkway', '0330228577', '1945/06/14', '1975/02/26', 'M', 'kbrahmbd@posterous.com', 'hN5<i2t.xRR4P', '2005/04/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV367893', 'Lucy Huzzey', '36738 Westend Road', '0701327864', '1958/07/21', '1964/06/05', 'M', 'lhuzzeybe@technorati.com', 'sQ9?#zxmuB', '1976/05/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV083506', 'Roana Balstone', '656 Loftsgordon Road', '0399177569', '1974/04/22', '1980/05/21', 'F', 'rbalstonebf@rambler.ru', 'sS2?e&drkl', '1977/11/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV036410', 'Nelie Bertram', '00031 Crest Line Way', '0922508685', '1989/09/25', '2001/01/18', 'M', 'nbertrambg@dropbox.com', 'jU2._$1vtGA8j1', '1982/07/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV959443', 'Rabbi Bangiard', '2799 Kipling Alley', '0887738964', '1981/10/02', '2009/08/31', 'M', 'rbangiardbh@reference.com', 'wH7{o8b8f>f', '1984/04/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV046742', 'Maureene Verling', '7 Everett Parkway', '0126461646', '2002/10/18', '1976/02/05', 'M', 'mverlingbi@about.com', 'uH9"O_=~kHz', '1969/12/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV134967', 'Carolina Squibbes', '76283 Park Meadow Circle', '0897269709', '1993/09/30', '1985/01/05', 'F', 'csquibbesbj@exblog.jp', 'cG7\ZJhzfI', '2016/08/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV138088', 'Ernesto Brandin', '4 Butternut Street', '0166426735', '1958/04/18', '1997/08/27', 'M', 'ebrandinbk@google.pl', 'dC8#@OepU~S\', '2016/03/04', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV789781', 'Analiese Wimpress', '0 Namekagon Center', '0145600059', '1975/12/03', '1987/08/03', 'F', 'awimpressbl@usda.gov', 'mF0>0''eA&BE#', '2021/06/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV328746', 'Agata Straughan', '577 Namekagon Parkway', '0242112331', '2004/11/03', '1975/07/21', 'M', 'astraughanbm@businesswire.com', 'nT4_5ESH8vzr', '1991/08/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV849000', 'Adiana Matuska', '910 Brentwood Street', '0988098347', '1974/08/15', '2014/09/09', 'M', 'amatuskabn@macromedia.com', 'cD6/.A.=~xJ', '1984/07/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV149072', 'Ana Chatain', '3 David Court', '0963464289', '1993/06/10', '1968/02/09', 'F', 'achatainbo@about.com', 'hS5@\JB{G', '1971/07/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV928013', 'Bee Fouldes', '35711 Prairieview Hill', '0362049387', '1975/07/09', '1999/08/09', 'F', 'bfouldesbp@reverbnation.com', 'jF2~!zom~fq"%zu', '2002/11/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV073871', 'Calida Blainey', '2 Bellgrove Parkway', '0802409627', '1966/12/11', '1992/05/20', 'M', 'cblaineybq@phpbb.com', 'qX0%aE1,7MB', '2000/12/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955885', 'La verne Roderick', '9819 Forest Run Hill', '0382801971', '1950/01/14', '2018/09/06', 'M', 'lvernebr@skype.com', 'mN3=7v{`Ght<CV', '2019/03/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV376524', 'Nancie Melvin', '98 Sherman Place', '0480477992', '1980/09/26', '2002/06/06', 'F', 'nmelvinbs@virginia.edu', 'wT3~gPz''q_b/&?', '2004/07/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV445723', 'Tedd Blaw', '01883 Westport Junction', '0665095472', '1975/12/05', '1969/11/12', 'F', 'tblawbt@mozilla.com', 'hF3<w$vw5CQ<s', '1964/12/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV782515', 'Ellsworth Kindall', '460 Grover Plaza', '0688359793', '1951/10/02', '1995/11/13', 'F', 'ekindallbu@php.net', 'tV9\R1TCd7"s', '1970/12/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV620763', 'Eleanora Aubery', '877 Raven Crossing', '0789557631', '1950/12/28', '1970/12/05', 'M', 'eauberybv@addtoany.com', 'bQ8?TNFs|H"nzt', '2005/11/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV122335', 'Liuka Letterese', '20418 Tomscot Plaza', '0381508700', '1970/04/20', '1977/02/01', 'M', 'lletteresebw@reference.com', 'bK6?&je"ozM''', '2011/04/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV464663', 'Maurise Ancliffe', '9 Daystar Park', '0466025270', '1996/02/01', '2015/05/10', 'F', 'mancliffebx@smugmug.com', 'vC1+zBtde9vqce+D', '2006/02/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV182814', 'Mohammed Esslement', '17 Morningstar Lane', '0392326949', '1984/02/21', '2013/11/16', 'M', 'messlementby@intel.com', 'wO7`*8TzHx561', '1989/12/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV413814', 'Franklyn Passman', '3455 Dottie Parkway', '0038331397', '1971/03/01', '2001/06/15', 'F', 'fpassmanbz@ed.gov', 'hW6@gEP/T4Oxf''q', '2019/12/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV524281', 'Justus Lakin', '90 Leroy Junction', '0039595985', '1978/10/04', '2015/07/10', 'M', 'jlakinc0@senate.gov', 'oP3%`_U,WISse73u', '1982/06/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV193026', 'Frants Brushfield', '09 North Place', '0324121152', '1975/11/01', '1987/08/14', 'M', 'fbrushfieldc1@google.com.hk', 'eD5|{*qB', '1993/12/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV392461', 'Niels Haskins', '5651 Sommers Park', '0068381576', '1966/08/14', '1970/10/31', 'M', 'nhaskinsc2@furl.net', 'rU7/Yr6vZ4kW', '2022/08/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV012052', 'Ondrea Pigne', '16 Porter Plaza', '0511790839', '1971/03/05', '1986/05/15', 'F', 'opignec3@timesonline.co.uk', 'wS6{zP#_/nZy&', '1999/12/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV306641', 'Georg O'' Reagan', '2 Caliangt Alley', '0381434350', '1993/04/12', '1985/08/20', 'F', 'goc4@xrea.com', 'oM6"~O%+', '2006/07/28', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV639320', 'Sondra Blaise', '057 Muir Drive', '0537380184', '1975/08/12', '2000/05/14', 'F', 'sblaisec5@geocities.com', 'yG0)aYWs6@ZX8N&=', '2011/05/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV596585', 'Wyatt Tiltman', '23 Algoma Plaza', '0116691680', '1997/01/26', '2011/11/29', 'F', 'wtiltmanc6@rediff.com', 'qN2"EkT%dUG8', '1975/04/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV660217', 'Ibbie Pietroni', '84315 Gateway Way', '0657038222', '1966/09/17', '1975/01/15', 'M', 'ipietronic7@wired.com', 'uD6)/m~`4', '1977/12/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV261060', 'Samson Bradtke', '7 Oriole Parkway', '0004823810', '1997/09/16', '1973/08/11', 'F', 'sbradtkec8@army.mil', 'xC7?TmtA', '1965/12/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV238644', 'Artie Gallear', '31 Fordem Court', '0298472163', '1947/11/19', '2022/05/24', 'F', 'agallearc9@freewebs.com', 'bS6+HLNTw', '1982/03/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV367864', 'Pacorro Moffet', '017 Mcguire Street', '0011098376', '1998/07/23', '2020/01/07', 'F', 'pmoffetca@foxnews.com', 'kI0~HR?V%>{', '2010/03/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV556814', 'Lutero Brice', '42 Elka Avenue', '0093012304', '1967/11/30', '1973/12/24', 'M', 'lbricecb@home.pl', 'qQ9%2#sR"_KIYSzY', '1973/05/27', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV242340', 'Simone Eam', '3 Maryland Way', '0373510483', '1952/03/10', '1991/04/16', 'M', 'seamcc@soundcloud.com', 'cR2)YUw|@f%AWWO.', '1973/06/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV822716', 'Tatiana Wand', '7 Hallows Street', '0800133979', '1945/12/19', '1979/12/03', 'F', 'twandcd@tiny.cc', 'bH0>C48AmvFa0', '1985/08/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV079311', 'Stefania Mintrim', '4 Sommers Place', '0487265449', '1982/12/18', '2015/07/03', 'M', 'smintrimce@feedburner.com', 'eH1?la7\D#KK', '2023/05/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV037737', 'Saunderson Witcomb', '35633 Arapahoe Park', '0008836062', '1985/10/14', '2021/09/23', 'F', 'switcombcf@usnews.com', 'aO6|wbz~M', '2013/12/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV890100', 'Guinna Shimon', '4 Onsgard Avenue', '0485295523', '1955/02/02', '2021/02/11', 'M', 'gshimoncg@creativecommons.org', 'hT2+id15NTB=46', '2022/11/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV269924', 'Angie Warsop', '475 Cody Circle', '0000929988', '1995/05/18', '1971/11/22', 'M', 'awarsopch@kickstarter.com', 'bA3>xD)*%f?%', '2021/10/13', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV137520', 'Michale Ledson', '3414 Pawling Court', '0221891164', '1962/07/14', '2017/08/07', 'M', 'mledsonci@cornell.edu', 'cZ1\g?5.', '2012/10/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV363798', 'Olvan Woodham', '69689 Schlimgen Center', '0783242715', '1974/04/13', '2002/04/03', 'M', 'owoodhamcj@4shared.com', 'rT9~NO.<(FK', '2021/07/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV262355', 'Cindelyn Pile', '56574 Center Court', '0996529870', '1968/06/02', '1972/06/18', 'F', 'cpileck@house.gov', 'vP9!KSw(H3', '2013/12/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV267858', 'Ysabel Batchelour', '867 Elka Center', '0557743605', '1973/05/09', '1987/08/04', 'F', 'ybatchelourcl@bluehost.com', 'mL1%_Hc7F)', '1972/07/16', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV861669', 'Torrence Hentze', '7412 Coleman Park', '0622598937', '1991/07/19', '2013/08/28', 'F', 'thentzecm@bravesites.com', 'zU1/aC|HXH7n', '1998/10/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV511516', 'Maressa Rowntree', '36887 Bayside Junction', '0972470599', '1971/10/06', '2001/04/01', 'F', 'mrowntreecn@mashable.com', 'vO2)Y\@3B$q', '1965/10/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV368307', 'Sean Lancaster', '17828 Cottonwood Crossing', '0539522399', '1985/02/11', '1969/10/03', 'F', 'slancasterco@toplist.cz', 'tM9<TyJDgD,e,', '1977/04/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV372997', 'Isidro Etchells', '5 Carpenter Way', '0010889315', '1972/06/04', '1967/08/05', 'M', 'ietchellscp@samsung.com', 'fX3|W"O!R''tHRr!}', '1971/10/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV676918', 'Taylor Gelletly', '83164 Leroy Crossing', '0380920639', '1979/11/28', '2009/11/19', 'F', 'tgelletlycq@bigcartel.com', 'zK9.a+BlY', '1978/02/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV262532', 'Thorstein Norewood', '49 Village Crossing', '0941998595', '1974/12/25', '1986/11/22', 'M', 'tnorewoodcr@bbc.co.uk', 'zL8/xsw%%f', '1981/06/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV167598', 'Hattie Gasparro', '57 Eliot Park', '0331005415', '1985/03/13', '2014/04/17', 'M', 'hgasparrocs@msu.edu', 'pC9.1+u*', '1970/02/12', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV112254', 'Kit Conman', '8 Rigney Plaza', '0065167598', '1978/05/29', '2014/06/17', 'M', 'kconmanct@chicagotribune.com', 'dS9%&`=%#`XJX}Z', '1980/11/23', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV645678', 'Quincy Barneville', '122 Twin Pines Road', '0832708962', '1948/01/13', '2002/04/11', 'F', 'qbarnevillecu@oakley.com', 'cK5!%n62{', '2007/12/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV339957', 'Jeth Purton', '013 International Pass', '0755142627', '1995/11/08', '2006/02/24', 'F', 'jpurtoncv@aboutads.info', 'yI5.|j&L)p)Y', '2021/07/08', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV035908', 'Iago Serjeant', '30 Killdeer Terrace', '0851736728', '1955/01/30', '2012/06/12', 'M', 'iserjeantcw@de.vu', 'bL1$"BfE}', '1987/10/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV981235', 'Magdalen Sawfoot', '5331 Kedzie Street', '0798964737', '1994/07/28', '1982/01/08', 'M', 'msawfootcx@wikipedia.org', 'yZ4>B7~FwyJ8j.qv', '1978/04/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV810826', 'Shurwood Fargie', '262 Luster Street', '0190480450', '2003/05/26', '1984/12/25', 'F', 'sfargiecy@over-blog.com', 'qZ4?rs*U0_yrdr', '2000/12/26', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV122392', 'Johnathon Austing', '2154 Mesta Avenue', '0803429950', '1962/09/10', '2018/04/14', 'F', 'jaustingcz@cafepress.com', 'pW1|EV+t', '1983/03/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV619036', 'Josh Carnilian', '082 Glacier Hill Alley', '0095312046', '1999/05/18', '2004/04/22', 'M', 'jcarniliand0@webeden.co.uk', 'gC4?R2Z8`g%jl"', '2008/11/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV994107', 'Obie Burndred', '9299 Havey Lane', '0603238742', '1980/04/14', '2023/05/16', 'F', 'oburndredd1@phoca.cz', 'bD5$kPbQVQ', '1975/07/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV690539', 'Alisun Lumber', '654 Mariners Cove Park', '0690683340', '1983/03/09', '1964/05/21', 'F', 'alumberd2@icq.com', 'aF2''>hzO', '1974/09/06', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955706', 'Hubie Rayner', '45 Eastlawn Parkway', '0454294540', '1974/01/23', '2012/08/02', 'M', 'hraynerd3@ameblo.jp', 'nX8?s.6{RY', '2017/03/11', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV301866', 'Tommy Caulwell', '205 Elka Lane', '0584148166', '1970/07/28', '1982/01/30', 'F', 'tcaulwelld4@home.pl', 'eM6~`v%u1&9*u*', '1970/10/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV234271', 'Bone Crace', '05 Marquette Pass', '0920822440', '1979/08/24', '1983/10/22', 'F', 'bcraced5@istockphoto.com', 'kD3%shkY@', '2020/03/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV660753', 'Gray Ventris', '9515 Havey Park', '0038648797', '1945/06/20', '1964/01/28', 'M', 'gventrisd6@networksolutions.com', 'bO5+yGbv', '2001/03/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV164312', 'Nollie Jirka', '4665 Carey Junction', '0432345500', '1951/11/21', '1973/09/16', 'M', 'njirkad7@newyorker.com', 'gZ9"h|QbJs', '1997/05/21', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV371090', 'Jeromy Brandsma', '68688 Oneill Drive', '0598190866', '1959/01/29', '2018/08/22', 'M', 'jbrandsmad8@ow.ly', 'gB5''RRUrlCAh&p', '2006/04/22', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV594273', 'Brigid Kolakowski', '7 Dorton Circle', '0953902659', '1950/03/25', '1983/02/21', 'F', 'bkolakowskid9@liveinternet.ru', 'jD9%|n7WcB\qc', '2010/07/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV258946', 'Brigid Baile', '67 Michigan Street', '0913857643', '1952/08/30', '2012/06/01', 'M', 'bbaileda@webs.com', 'sX4,B`8utkolkgQ', '1997/04/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV245600', 'Zonnya Pughsley', '017 Merrick Street', '0202863249', '1957/07/08', '1995/12/17', 'M', 'zpughsleydb@va.gov', 'hL0!NR8e''~', '1990/05/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV461683', 'Sherwin Osan', '588 Hauk Circle', '0636500751', '1988/04/24', '1976/08/30', 'F', 'sosandc@oracle.com', 'gL7%bRAjgm~Is2hP', '2007/05/24', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV349936', 'Gianna Ruslin', '37 Mcbride Street', '0447722803', '1983/07/07', '1967/07/27', 'F', 'gruslindd@imageshack.us', 'oT7@G#B8F~369H', '2021/07/18', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV985849', 'Liv Ferrini', '8 Acker Drive', '0933793936', '1952/11/14', '2014/09/07', 'F', 'lferrinide@psu.edu', 'sP4=)UKH.,Z0', '2005/10/02', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV992229', 'Shawn Bridson', '9670 Logan Place', '0637884935', '1960/05/24', '1985/11/01', 'M', 'sbridsondf@intel.com', 'qM9#lnW|X/!8', '2009/11/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV610092', 'Nina Epine', '94996 Rutledge Crossing', '0950340745', '1950/07/12', '1997/05/20', 'F', 'nepinedg@wp.com', 'qP6&&>6n2)FQ/j', '2002/01/20', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV964113', 'Valera Luck', '17 Corry Park', '0793268002', '1947/05/10', '2003/05/04', 'F', 'vluckdh@icq.com', 'fK7=,iCZF', '2012/10/14', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV433504', 'Diana Blanket', '380 Carpenter Drive', '0604869147', '1951/10/22', '2003/03/10', 'M', 'dblanketdi@yelp.com', 'dA8+sTsw', '2005/08/29', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV405196', 'Abbot Fenge', '29 Shoshone Terrace', '0843026272', '1995/05/01', '1973/08/21', 'F', 'afengedj@com.com', 'yE6?1#L9K', '1975/04/09', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV303957', 'Jemima O'' Quirk', '273 Express Drive', '0606590703', '1947/10/21', '2004/11/27', 'M', 'jodk@google.ru', 'nW6=jjTMeWi2(*', '2017/01/01', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV921688', 'Dianne Loving', '4796 Memorial Park', '0886454292', '1949/06/26', '2000/08/25', 'M', 'dlovingdl@patch.com', 'hQ9}qI"S08', '2004/12/15', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV832790', 'Prent Sellors', '5 Sutteridge Crossing', '0469800545', '1948/03/15', '1978/12/11', 'F', 'psellorsdm@java.com', 'uP0@Rn9uqaq', '1981/04/30', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV585662', 'Breanne Ensten', '14 Thackeray Circle', '0975842561', '1985/12/24', '1972/09/11', 'M', 'benstendn@jalbum.net', 'fQ2|BO8CdB@EnkF', '2008/10/10', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV415824', 'Melitta Callingham', '760 Holmberg Street', '0196348348', '1982/02/06', '1997/04/13', 'M', 'mcallinghamdo@craigslist.org', 'vX9}X1*W~yq', '2018/11/25', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV303199', 'Karney Ogborn', '86 Kipling Center', '0362886993', '1977/08/29', '1994/06/26', 'F', 'kogborndp@jigsy.com', 'cS9,\4sn5)N_I', '2001/02/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV105604', 'Laughton Endon', '76 Sutteridge Street', '0321040937', '1945/09/15', '1970/09/15', 'M', 'lendondq@bloomberg.com', 'vW3*q3h*', '2010/02/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV440528', 'Danyelle Pettit', '87522 Fisk Place', '0228623581', '1965/08/28', '1980/06/29', 'M', 'dpettitdr@miibeian.gov.cn', 'eG5/G0ZuT>H!', '2015/04/17', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV185967', 'Tremaine Corneliussen', '937 Dapin Center', '0275549224', '1966/02/22', '2011/09/21', 'F', 'tcorneliussends@mit.edu', 'xJ6"i~cExwV', '2004/02/03', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV955852', 'Abrahan Pilling', '26 Arizona Street', '0573401445', '2005/09/29', '1985/03/06', 'F', 'apillingdt@edublogs.org', 'jU0)Nq*g|{''iCou', '1980/11/05', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV057942', 'Cissy Ughetti', '2 Golf Course Drive', '0952993939', '1950/02/15', '1991/10/06', 'F', 'cughettidu@imageshack.us', 'nD5`6z6Pm=', '2020/12/07', 'NV');
insert into NHANVIEN (MANV, TENNV, DIACHI, SODT, NGAYSINH, NGAYVAOLAM, GIOITINH, EMAIL, PASSWORD, NGAYTAOTK, MAVT) values ('NV582109', 'Ola de Tocqueville', '58223 Elka Point', '0449860223', '1972/11/29', '1975/02/04', 'M', 'odedv@blogger.com', 'iK9_qR_!=YN', '1989/06/04', 'NV');

GO
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH099823', 'Bree Wanek', 'F', '1985/07/16', '0665563123180', '1989/03/12', 'Zambia', '0545189589', 'bwanek0@hostgator.com', '76206 Rieder Terrace', 'fN8>%_V#7>', '2005/12/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH594915', 'Elvira Andryushin', 'M', '2001/05/17', '0121436551690', '1969/07/28', 'Brazil', '0992457682', 'eandryushin1@toplist.cz', '56328 Parkside Drive', 'rO2@"7YCB', '2016/04/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH758557', 'Sarge Sheddan', 'F', '1976/10/27', '0160363143249', '1976/06/18', 'Russia', '0836565852', 'ssheddan2@simplemachines.org', '19 Charing Cross Street', 'wH5|c<r?/V&7', '2023/05/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH296175', 'Stevena Boliver', 'M', '1953/09/20', '0166318845470', '1967/12/27', 'China', '0040057954', 'sboliver3@flickr.com', '32 Southridge Place', 'iG7~TFsb&g1', '1974/02/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH823023', 'Ryley Matzel', 'M', '1991/08/13', '0053357478458', '1995/10/26', 'Indonesia', '0002881019', 'rmatzel4@umich.edu', '199 Granby Street', 'xP4"#a)}2VVxO', '1980/08/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH462984', 'Cary Burkitt', 'F', '1990/11/15', '0680718366479', '1973/12/29', 'Turkey', '0915067331', 'cburkitt5@w3.org', '33 Red Cloud Terrace', 'gE5@+cmUI2st=RH', '2008/03/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH412474', 'Torrence Trewhela', 'F', '1997/03/06', '0062089127377', '1986/07/22', 'China', '0796882641', 'ttrewhela6@godaddy.com', '97209 Hermina Drive', 'qA3@Q(%Fpfj9', '1974/08/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH069945', 'Siward Jolly', 'M', '1972/05/03', '0743618097521', '1989/04/22', 'Russia', '0105314368', 'sjolly7@google.ru', '772 Southridge Park', 'xF2}rmvnRb8G=ZAp', '1990/05/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH054833', 'Craggy O''Loinn', 'M', '1985/04/08', '0196681280440', '1969/06/09', 'Morocco', '0475572442', 'coloinn8@usgs.gov', '0850 Montana Alley', 'qZ9{y6/5y', '2017/06/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH949953', 'Mariquilla Whiteland', 'F', '1961/12/19', '0545208581597', '1990/03/18', 'Venezuela', '0487110341', 'mwhiteland9@scientificamerican.com', '78722 Tennyson Court', 'aD8?1hN&(,p', '1972/08/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH488527', 'Roth Marrian', 'M', '1951/07/16', '0144875643398', '1985/08/21', 'Bosnia and Herzegovina', '0124280075', 'rmarriana@icq.com', '461 Hermina Street', 'eY4@SM@l\', '2011/01/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH462707', 'Rudolph Islip', 'F', '1962/02/12', '0632089234489', '2018/07/07', 'Poland', '0459437649', 'rislipb@arizona.edu', '4097 Sommers Court', 'dT0`aNS2J?', '2002/04/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH372608', 'Colver Lightfoot', 'F', '1995/03/03', '0260454034032', '2005/07/07', 'Pakistan', '0851299008', 'clightfootc@technorati.com', '10 Ridge Oak Crossing', 'xD6+Twx1v\gc!QF', '1991/08/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH418540', 'Perceval Ungerecht', 'M', '1960/01/19', '0590470733550', '1998/07/04', 'China', '0236975790', 'pungerechtd@cbc.ca', '1911 Ridge Oak Pass', 'yU3.onb|&mA.e)m', '2012/11/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH672845', 'Noam Hanmore', 'F', '1980/03/24', '0199846690199', '1999/08/23', 'Dominica', '0886449506', 'nhanmoree@altervista.org', '6461 Vermont Street', 'hV7<QakG+''v!!', '1972/07/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH344217', 'Gerrie Glanvill', 'F', '1980/08/09', '0488188834901', '2005/07/02', 'China', '0464993347', 'gglanvillf@google.pl', '40 Utah Plaza', 'fM9}BRp}uvNa', '1985/12/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH860169', 'Trish Flemyng', 'M', '1986/08/07', '0038980220517', '2009/10/17', 'China', '0022606452', 'tflemyngg@icq.com', '9969 Glendale Place', 'bM9"@D"TGYQpIhx', '2021/12/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH039286', 'Isobel Treasure', 'F', '1955/07/13', '0646501215041', '2003/04/22', 'France', '0249596081', 'itreasureh@bloglines.com', '29104 Warbler Place', 'mY4\3CO_}}g$aA`B', '2000/05/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH563845', 'Helge Battany', 'M', '2000/03/30', '0916718146704', '2013/05/04', 'Argentina', '0908740460', 'hbattanyi@alexa.com', '1 Loeprich Point', 'sY0/KVY4eJiqje=J', '1970/10/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH398577', 'Gypsy Dennick', 'F', '1961/10/26', '0289290867559', '1993/12/03', 'Czech Republic', '0459272725', 'gdennickj@purevolume.com', '03268 Ilene Circle', 'xG8/$gdg', '1976/06/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH442934', 'Chloe Chadbourne', 'M', '1957/05/28', '0841104848369', '2001/07/09', 'Sweden', '0901541580', 'cchadbournek@tuttocitta.it', '13602 Ludington Point', 'hG8#N4V*@uet', '2007/11/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH464938', 'Mariellen O''Spellissey', 'F', '1977/01/04', '0635867151852', '2019/03/07', 'Poland', '0013198339', 'mospellisseyl@nature.com', '99662 Graceland Point', 'vO1.R+Lrl7`', '1985/07/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH065196', 'Pepe Durward', 'F', '1957/10/02', '0857730164844', '1971/11/23', 'Russia', '0424351307', 'pdurwardm@cdc.gov', '51 Scott Circle', 'vP1/pGgwkJNV', '2004/08/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH575389', 'Ilene Rochell', 'F', '1967/12/26', '0400175530564', '1979/04/16', 'Indonesia', '0904196173', 'irochelln@phoca.cz', '2022 Del Sol Trail', 'tD0=imL#/$`', '1993/11/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH008583', 'Ingaberg Hambling', 'M', '1983/02/27', '0313928510752', '2012/08/04', 'Cameroon', '0748910864', 'ihamblingo@sina.com.cn', '9332 Surrey Court', 'aY8{''bL1jm|', '1975/06/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH895693', 'Ree Maudett', 'F', '1970/03/16', '0788893313054', '1992/12/25', 'Thailand', '0593586368', 'rmaudettp@networksolutions.com', '319 Fulton Junction', 'vO3$*n=v', '2012/12/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH934191', 'Tyrus Boater', 'F', '1963/06/14', '0777124941608', '1987/10/20', 'China', '0905494299', 'tboaterq@amazonaws.com', '0 Oakridge Road', 'rF4}4\''A!=*', '1995/11/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH123384', 'Sandi Brome', 'F', '1995/09/30', '0317991376373', '1989/07/05', 'China', '0684293094', 'sbromer@behance.net', '6 Fair Oaks Way', 'vN6)y>m>', '1977/03/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH128603', 'Ripley Lebbern', 'M', '1964/04/25', '0584958828816', '2002/03/07', 'Mauritius', '0619395639', 'rlebberns@gizmodo.com', '83465 Westridge Plaza', 'uB2?d{9X2(K', '2012/03/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH757285', 'Martie Ringwood', 'F', '1954/09/26', '0573542840110', '1987/09/21', 'China', '0885495679', 'mringwoodt@facebook.com', '14 Hagan Plaza', 'wC7&.3<,Pes', '2023/11/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH013444', 'Lonna Coil', 'M', '1985/04/12', '0198547578502', '1980/05/18', 'Philippines', '0745189786', 'lcoilu@mit.edu', '50571 Tennyson Drive', 'pH6{gPdIT<1,(+V{', '1972/04/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH582692', 'Vail Guerry', 'M', '1978/06/15', '0658397610813', '1983/10/09', 'United States', '0675940226', 'vguerryv@amazon.co.uk', '71816 Beilfuss Parkway', 'tQ7?PuPIskoHJ', '1972/08/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH477186', 'Benjamen Epine', 'F', '1994/11/30', '0355653848359', '2016/01/15', 'Tanzania', '0229208695', 'bepinew@google.ru', '68 Fremont Street', 'fF4/Iuw7hZZ%VOr', '2012/02/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH977771', 'Agnes Orteaux', 'M', '1952/02/20', '0612174501441', '1995/07/02', 'Russia', '0286035214', 'aorteauxx@google.co.jp', '827 Jenifer Plaza', 'tC7)i2''!f\"Rch3', '1966/01/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH118901', 'Bernetta Beste', 'M', '1957/07/25', '0462667396718', '1977/09/24', 'United States', '0536883006', 'bbestey@techcrunch.com', '7 Esker Center', 'bH8?\yQb&r&', '2007/11/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH099791', 'Pace Pottinger', 'F', '1959/09/27', '0606830030257', '1988/04/18', 'China', '0634140308', 'ppottingerz@qq.com', '71837 Stang Hill', 'jG6''''}FO?hFq`', '1969/05/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH146019', 'Valma Cullinan', 'M', '2001/01/13', '0166788071536', '2003/07/04', 'Colombia', '0905009887', 'vcullinan10@craigslist.org', '04470 Fieldstone Drive', 'yM1=i0F+|', '2019/01/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH243684', 'Thorsten Diplock', 'M', '1950/03/23', '0887213104732', '2019/02/22', 'Thailand', '0570994536', 'tdiplock11@hp.com', '3 John Wall Trail', 'eU2=,a2#Uw(', '2016/12/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH355802', 'Charlton Romain', 'M', '1989/12/10', '0975477664106', '2002/01/03', 'China', '0495876128', 'cromain12@state.tx.us', '5955 Troy Plaza', 'oQ2#A}b&=,tTL', '2014/01/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH225452', 'Hank Leverington', 'M', '1988/05/14', '0252635712911', '1966/06/23', 'Indonesia', '0099044868', 'hleverington13@merriam-webster.com', '06684 Manitowish Pass', 'mE3_L8So', '1968/12/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH046243', 'Malanie Rennix', 'M', '1945/05/05', '0704560839083', '1992/09/04', 'China', '0781684694', 'mrennix14@purevolume.com', '57880 Sage Road', 'hF6}PME=U77stu', '1997/01/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH306439', 'Lind Wankel', 'F', '1954/09/19', '0890537337352', '2016/08/19', 'Indonesia', '0600685891', 'lwankel15@sphinn.com', '44 Hanover Trail', 'rU6+/W\b2\', '2014/07/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH334932', 'Archambault Slayford', 'M', '1966/07/05', '0336009281798', '2001/01/10', 'France', '0488422469', 'aslayford16@ftc.gov', '856 Algoma Alley', 'gV2.XQ<f', '1988/05/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH393702', 'Hallie Firman', 'M', '1958/11/18', '0866309135612', '1975/03/03', 'Colombia', '0246575260', 'hfirman17@jalbum.net', '8 Mesta Court', 'mD8_?2qheqV', '1973/02/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH991187', 'Rickey Stoneham', 'F', '1992/03/06', '0013701561344', '1991/01/28', 'Poland', '0350875281', 'rstoneham18@kickstarter.com', '4 Ridgeway Street', 'qG0?0+IS|0i', '1994/09/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH669899', 'Julianna Hasnney', 'M', '1995/04/30', '0565739065631', '1977/11/26', 'Poland', '0568772884', 'jhasnney19@freewebs.com', '9 Saint Paul Parkway', 'mC8(oz~*N6f3$7\O', '1989/04/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH285533', 'Alicea Cud', 'M', '1967/08/09', '0703460299628', '2006/11/15', 'China', '0417759767', 'acud1a@behance.net', '5 Vermont Street', 'iH0*j`iz%Q', '1988/08/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH382525', 'Rosanne Mortlock', 'F', '1964/04/30', '0471128400307', '2024/01/22', 'Honduras', '0630482665', 'rmortlock1b@altervista.org', '6 Mosinee Lane', 'eB2(J(uL/xbzS', '1965/12/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH669308', 'Sanders Bremen', 'M', '1948/01/10', '0706869044798', '2015/01/03', 'China', '0186070568', 'sbremen1c@si.edu', '1918 Washington Park', 'vY1''bu5!', '1980/02/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH448966', 'Chrissy Sarl', 'M', '1958/01/31', '0745590064939', '1986/12/15', 'China', '0735231838', 'csarl1d@mayoclinic.com', '9 Springview Place', 'iA3''8#=Dr', '1991/04/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH486524', 'Whitman Girardez', 'F', '1955/03/22', '0112046791089', '2002/10/19', 'Poland', '0335111549', 'wgirardez1e@cnn.com', '74 Crownhardt Drive', 'jM0,8NlQD8Khx', '1969/08/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH914683', 'Lezlie Vest', 'M', '1993/05/04', '0767202324407', '2016/07/14', 'United States', '0446613518', 'lvest1f@reverbnation.com', '06 Lindbergh Street', 'qI4+Mp7uY@Fw3<', '2002/05/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH247508', 'Robinet Keems', 'F', '1991/05/01', '0096868041255', '2019/09/08', 'China', '0064868425', 'rkeems1g@chicagotribune.com', '1 Namekagon Trail', 'gL1_K2a8>LADpi5', '1995/11/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH786340', 'Dorene Oakinfold', 'F', '1985/06/09', '0936084323319', '2017/02/13', 'Philippines', '0597284346', 'doakinfold1h@delicious.com', '511 Burrows Trail', 'hX7?#E~eb_6', '1985/12/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH104498', 'Lilian Cosson', 'M', '1971/03/01', '0277579681576', '1999/12/03', 'Indonesia', '0121998492', 'lcosson1i@patch.com', '909 Colorado Circle', 'wK5,QQ2fK$2', '1994/08/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH451306', 'Suellen Allmark', 'F', '1961/08/08', '0620568372694', '1968/01/26', 'Oman', '0511559641', 'sallmark1j@china.com.cn', '2 Ohio Road', 'bP2)R2\(i)%{>KO', '1996/06/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH314999', 'Cathleen Patnelli', 'F', '1949/01/18', '0315258219009', '1992/03/09', 'Vietnam', '0351682920', 'cpatnelli1k@stumbleupon.com', '6 Glacier Hill Avenue', 'uW0)MrKeQQrN', '2017/05/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH566730', 'Korie Grayshan', 'M', '1988/10/25', '0567689891287', '2013/06/28', 'Poland', '0584409504', 'kgrayshan1l@tinypic.com', '40218 Kinsman Crossing', 'mY9(L#mLu#7', '2024/05/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH820633', 'Dunc Quodling', 'M', '1969/10/17', '0165836790977', '1988/09/30', 'Comoros', '0420124372', 'dquodling1m@pinterest.com', '948 Westridge Point', 'hD4`TDp18W9+!', '1993/01/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH237493', 'Britte Myrkus', 'F', '1977/09/08', '0596719419836', '2003/05/17', 'Japan', '0076113631', 'bmyrkus1n@gravatar.com', '32386 Rieder Place', 'dL8+`f\yShHc', '1972/08/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH780705', 'Ivette Noads', 'F', '1966/06/26', '0029042595262', '2003/02/05', 'Indonesia', '0102158458', 'inoads1o@baidu.com', '28 Lighthouse Bay Street', 'bI8#u"cX', '2012/02/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH949047', 'Coraline MacGillivrie', 'F', '1991/09/09', '0049556801332', '1966/10/31', 'China', '0676634644', 'cmacgillivrie1p@ed.gov', '1987 Rigney Lane', 'vB8%o|JW9', '2018/08/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH437409', 'Virgil Recke', 'M', '1971/05/17', '0584500414853', '1988/08/25', 'China', '0226158769', 'vrecke1q@flickr.com', '97 Golden Leaf Hill', 'fT5*wn{r>Zz8nR', '1993/08/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH857208', 'Falito Gerding', 'M', '1973/05/27', '0837601389982', '2013/02/03', 'Russia', '0290223449', 'fgerding1r@answers.com', '9 Spohn Circle', 'nQ2}q,AZ>', '1991/06/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH266770', 'Kettie Ruddoch', 'F', '1978/11/07', '0535046753978', '1976/08/26', 'Ireland', '0561463244', 'kruddoch1s@issuu.com', '82 Ludington Way', 'lU6?YXOM1|uyc<kH', '1980/07/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH419726', 'Huntlee Ruffler', 'F', '1992/05/18', '0648614223001', '2024/06/10', 'Brazil', '0275185940', 'hruffler1t@walmart.com', '6605 Village Green Center', 'nE3@qQATR>W', '1988/05/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH974232', 'Chloe Casburn', 'F', '1992/11/15', '0174903907438', '1965/06/06', 'Portugal', '0026109872', 'ccasburn1u@360.cn', '445 Vidon Place', 'pJ1*x@Md6a6', '1965/11/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH285098', 'Iago Mallall', 'F', '1962/08/06', '0447108623155', '1977/03/04', 'Mexico', '0919871831', 'imallall1v@mayoclinic.com', '36387 Erie Trail', 'uF6?,nVzgG|6R8f', '1985/05/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH022658', 'Jerry Court', 'M', '2004/01/01', '0937119404880', '2009/06/27', 'Portugal', '0570802330', 'jcourt1w@themeforest.net', '084 Delaware Terrace', 'kA7<alKjD*kmR}6', '1980/10/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH330627', 'Hunt Lowndsbrough', 'M', '1960/09/09', '0870942958404', '1997/10/23', 'China', '0132968275', 'hlowndsbrough1x@skyrock.com', '84 Morning Alley', 'kO1(aC{XI', '1967/03/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH732493', 'Gayle Bayfield', 'M', '1960/07/08', '0988707615399', '2008/07/06', 'China', '0888102811', 'gbayfield1y@mozilla.org', '001 Birchwood Circle', 'kD1|R<LRm', '1966/02/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH350452', 'Brett Dorn', 'M', '1968/11/05', '0838564253331', '2000/08/26', 'Hungary', '0440235096', 'bdorn1z@nymag.com', '2455 Packers Court', 'mL7>rI)9', '1975/07/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH554185', 'Vinnie Dendle', 'M', '1983/11/15', '0227857364298', '1995/09/04', 'China', '0244386039', 'vdendle20@icio.us', '9435 Kinsman Pass', 'hW4?ZPU@4O', '2017/08/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH884843', 'Joana Pantlin', 'M', '1948/05/18', '0441379940741', '2023/07/03', 'Indonesia', '0877286761', 'jpantlin21@blogspot.com', '40 Norway Maple Alley', 'pJ1!8OH9', '1963/08/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH315582', 'Brit St. Ledger', 'M', '1982/11/20', '0483762060629', '1989/01/21', 'Sweden', '0916335051', 'bst22@i2i.jp', '91 Glacier Hill Park', 'qD8_o/G9C>j1,t3@', '2002/09/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH537109', 'Jonah Yerbury', 'F', '1980/09/24', '0222511013590', '1969/03/24', 'Colombia', '0741514877', 'jyerbury23@zimbio.com', '2822 Magdeline Drive', 'uM3\?6n{FTRI9L,', '1974/11/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545858', 'Claribel Kimmons', 'M', '1979/04/23', '0056893066919', '1983/04/25', 'China', '0122270876', 'ckimmons24@dion.ne.jp', '10980 Clemons Crossing', 'cQ1+ZgCAw$6Q', '2019/07/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH066621', 'Nevins Romaine', 'M', '1997/11/14', '0566023601518', '1999/09/06', 'China', '0800602874', 'nromaine25@google.co.uk', '11039 Lukken Trail', 'zX3&&v>m&A/Ls,', '2020/09/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH456126', 'Chancey Welldrake', 'F', '1970/06/06', '0523287873588', '2013/12/31', 'Mongolia', '0066115431', 'cwelldrake26@dropbox.com', '45865 Pleasure Circle', 'sT4`@/Dxb&6', '2022/03/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH029547', 'Angelina Portinari', 'F', '1973/02/25', '0134279115989', '1978/11/14', 'Indonesia', '0993416282', 'aportinari27@google.co.jp', '109 Hooker Road', 'gP9.eN//Nv"M<', '1974/12/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH773761', 'Korry Medgewick', 'M', '2002/11/13', '0712354975722', '2010/10/10', 'Morocco', '0452984495', 'kmedgewick28@themeforest.net', '06 Waxwing Trail', 'oY5!L%5D', '1969/10/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH684221', 'Ros Sylett', 'F', '2003/05/17', '0905118829454', '2002/08/24', 'Philippines', '0763300051', 'rsylett29@apache.org', '769 Darwin Drive', 'jG9"O0BfOS01', '1974/01/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH563902', 'Earl Hellens', 'F', '1964/01/29', '0927000373535', '1965/01/24', 'Ukraine', '0161979580', 'ehellens2a@upenn.edu', '6 Annamark Trail', 'wH3_O_DQhPxnu', '1999/11/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH481886', 'Abdul Bartomieu', 'M', '1948/12/16', '0212735499049', '1988/04/02', 'Portugal', '0482902634', 'abartomieu2b@hatena.ne.jp', '84774 Rusk Park', 'xX4)}lsCjg<}', '2011/08/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH704652', 'Molly Windeatt', 'F', '1998/09/07', '0387729154021', '1967/12/22', 'Belarus', '0500775305', 'mwindeatt2c@zdnet.com', '332 Jackson Circle', 'zG3\b*%PccpUc)Z', '1983/08/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH348292', 'Isahella Beever', 'M', '1958/11/03', '0617262131520', '2010/10/24', 'Peru', '0473652820', 'ibeever2d@smugmug.com', '7846 Kim Way', 'yJ1(wCU3uV2cBR', '2009/10/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH059888', 'Abdul Brimner', 'M', '1965/01/04', '0909438170980', '1985/05/04', 'Dominican Republic', '0435185851', 'abrimner2e@hc360.com', '893 Springview Point', 'sC2{CIC,8TS0C2', '1987/08/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH345195', 'Imojean Casham', 'F', '1979/05/18', '0476691212653', '2009/06/01', 'Iran', '0296398773', 'icasham2f@bizjournals.com', '14481 Burrows Crossing', 'rF5(6l|eDqsw', '2022/12/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH362680', 'Morey Greenlies', 'M', '1968/04/14', '0212498802394', '1991/03/07', 'Indonesia', '0775429174', 'mgreenlies2g@a8.net', '0 Talmadge Point', 'xC1<`.V.j$', '2011/12/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH079281', 'Norine Nutt', 'F', '1953/06/04', '0278216338696', '2011/08/18', 'Philippines', '0773360814', 'nnutt2h@ftc.gov', '166 Manley Place', 'vY3.J''?~%Ym', '2013/03/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH454006', 'Marlie Gyrgorwicx', 'M', '1958/08/30', '0543743135840', '2006/12/28', 'Bosnia and Herzegovina', '0605587644', 'mgyrgorwicx2i@intel.com', '9 Lawn Road', 'jX3@\nY.6%', '1986/05/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH939840', 'Trudy Bannell', 'M', '1968/02/10', '0072075561830', '2006/12/10', 'Portugal', '0840821999', 'tbannell2j@intel.com', '965 Columbus Parkway', 'jE2+(H6VD', '2005/09/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH666660', 'Westbrook Woollacott', 'F', '1995/12/08', '0654450772398', '2010/12/17', 'Uganda', '0436481182', 'wwoollacott2k@howstuffworks.com', '90864 Veith Circle', 'jE3_czZ`atgQ', '1972/12/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH297971', 'Maribel O''Scollee', 'M', '1961/10/09', '0563283013681', '2000/07/13', 'Indonesia', '0221110940', 'moscollee2l@com.com', '9 Marcy Alley', 'yR1{0@+RQA~ms8c$', '2001/06/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084753', 'Gardie Kimmel', 'M', '1967/06/20', '0425609761406', '1982/05/15', 'Brazil', '0367302459', 'gkimmel2m@merriam-webster.com', '98 Crest Line Pass', 'zF5$SaQR3IYLZSDo', '1988/07/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH059030', 'Anjela Sleightholme', 'F', '1988/06/30', '0711530051730', '1974/06/16', 'Czech Republic', '0348423376', 'asleightholme2n@spotify.com', '00689 Carberry Street', 'tQ8)=ivis\1Xko', '2014/04/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH614974', 'Orly Hartwright', 'F', '1965/02/16', '0039075918796', '1972/12/19', 'China', '0732092999', 'ohartwright2o@bloomberg.com', '384 Hooker Pass', 'wY3|uqOL5+bS', '1970/03/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH696026', 'Colan Keiley', 'M', '1949/11/14', '0692410756108', '2002/09/05', 'Indonesia', '0719891171', 'ckeiley2p@wikipedia.org', '73443 Mifflin Lane', 'bS9.T)w>G', '1992/09/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH558718', 'Amos Loudiane', 'M', '1992/10/17', '0870344771442', '1999/06/11', 'China', '0231320447', 'aloudiane2q@phpbb.com', '8602 Talisman Avenue', 'gU7}Aj<Z!qgPy@', '1969/08/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH157277', 'Reggy Yegorkin', 'M', '2000/07/07', '0992411044304', '2020/08/28', 'France', '0703573240', 'ryegorkin2r@paypal.com', '9695 Upham Avenue', 'oS1,x#aA.RqQLT=P', '1984/06/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH618984', 'Kalil Fearnall', 'F', '2004/06/30', '0149644118427', '1986/07/16', 'Philippines', '0893281592', 'kfearnall2s@dagondesign.com', '99023 Arkansas Terrace', 'bA2$`HSb0eD', '2014/10/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH408448', 'Nadya Getcliffe', 'M', '1989/02/11', '0622725852527', '1979/03/11', 'Czech Republic', '0621319402', 'ngetcliffe2t@youtu.be', '41 Dahle Way', 'xQ3{BMRz.3tXW', '1993/08/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH365036', 'Stephani Munkley', 'F', '1984/07/04', '0571769148281', '1995/10/17', 'China', '0015600068', 'smunkley2u@jigsy.com', '44556 Lakewood Pass', 'fO2(1d*Dq', '1977/04/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH375317', 'Anita Gligoraci', 'F', '1957/08/08', '0385229433811', '2006/03/31', 'Philippines', '0168025341', 'agligoraci2v@hud.gov', '135 Forest Run Road', 'lG7*I_Bh>P4{a4P', '1979/01/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH522691', 'Ninnette Mawtus', 'F', '1986/07/19', '0368604641537', '2011/05/02', 'Russia', '0143481228', 'nmawtus2w@nationalgeographic.com', '04 Namekagon Crossing', 'rH6}3$uLzxvt>J', '1976/10/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH867105', 'Caryn Duncan', 'M', '1976/11/12', '0785119687909', '2008/11/22', 'Yemen', '0147011365', 'cduncan2x@google.co.jp', '55 Grover Drive', 'cA9#7XPI&sUBK,=~', '2001/04/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH417478', 'Byrom Kruger', 'M', '1991/03/06', '0158543130820', '1976/05/05', 'China', '0187708483', 'bkruger2y@army.mil', '8 Onsgard Parkway', 'dD4`ZV}#>epV', '2023/05/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH473113', 'Giffy Leadstone', 'M', '1987/10/08', '0354374302988', '1985/09/05', 'Russia', '0188451658', 'gleadstone2z@wikispaces.com', '83492 Golf Course Street', 'jO7={.LM(6Sx|k', '1970/06/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374389', 'Almeda Goodbody', 'F', '2000/04/06', '0607402428656', '2015/11/18', 'Russia', '0127228617', 'agoodbody30@earthlink.net', '7253 Memorial Terrace', 'jI0}g=IINd', '1999/10/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH341501', 'Gaynor Leamy', 'F', '1955/07/13', '0568486167447', '2015/09/28', 'Guatemala', '0060473203', 'gleamy31@addtoany.com', '80097 Birchwood Avenue', 'rK5/OAQ/4r''{dtz', '1979/01/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH536661', 'Brendan Wyre', 'F', '1965/08/23', '0774278605771', '1984/02/06', 'China', '0140607703', 'bwyre32@slashdot.org', '4 Laurel Point', 'tS7>BjNTmj`\7\', '1969/09/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH225380', 'Aretha McMillan', 'M', '1982/07/31', '0925035989132', '2021/12/17', 'El Salvador', '0287074622', 'amcmillan33@ca.gov', '757 Bunting Crossing', 'gW3>9S56)', '2016/03/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH877635', 'Dolli Swindlehurst', 'M', '1960/09/18', '0256567735907', '1991/03/14', 'Serbia', '0302494718', 'dswindlehurst34@paginegialle.it', '4 Colorado Point', 'fQ1?|+id3NMFvd', '1990/10/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH808028', 'Audre Woolacott', 'M', '1994/07/14', '0257733263156', '1980/08/03', 'Armenia', '0382367704', 'awoolacott35@slashdot.org', '630 Cambridge Plaza', 'xV0<~W6>kduFOY_', '1976/10/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH347468', 'Bel Suche', 'M', '1955/08/14', '0656701310273', '1975/09/19', 'China', '0177641041', 'bsuche36@tinyurl.com', '95 Brown Plaza', 'wD5}JEwlC|$', '2018/12/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH399380', 'Griz Kingscott', 'M', '1986/03/07', '0002917719305', '1978/10/26', 'Canada', '0430843504', 'gkingscott37@icio.us', '0120 Monica Pass', 'vQ0*=){tufg', '1976/01/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH788966', 'Mariette Crawforth', 'F', '1952/07/19', '0635426604434', '1983/08/22', 'Nauru', '0048802491', 'mcrawforth38@gizmodo.com', '32448 Sloan Street', 'jQ9*g''(Ae~e', '2011/07/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH496697', 'Skelly Beet', 'F', '1991/04/13', '0131584554082', '2008/07/05', 'Indonesia', '0844498085', 'sbeet39@google.cn', '45 Logan Road', 'pC2%w3he', '1983/11/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH237192', 'Melly Mulroy', 'M', '1988/05/18', '0612755799388', '2019/11/22', 'Sri Lanka', '0922335045', 'mmulroy3a@irs.gov', '9 Eastlawn Plaza', 'hA1&PSM$E<SG', '1989/12/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH945522', 'Ninetta Paler', 'M', '2003/08/24', '0940394990020', '2021/07/02', 'Senegal', '0489380515', 'npaler3b@com.com', '1201 International Parkway', 'oU0$\Dxy1nJ/XwU', '1980/07/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH071341', 'Lexine Conaghan', 'F', '1945/11/18', '0565406693804', '2016/04/28', 'Malta', '0114202756', 'lconaghan3c@blogger.com', '1 Huxley Park', 'vX3*>j>@Cfn', '1964/11/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH234451', 'Mischa Lunbech', 'M', '1971/02/23', '0522483430629', '2003/01/06', 'China', '0343994663', 'mlunbech3d@macromedia.com', '3271 Aberg Trail', 'qA5&IVE~l|k', '1986/03/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH834272', 'Cory Depper', 'M', '1988/01/22', '0357562888503', '1983/06/19', 'Gambia', '0018914335', 'cdepper3e@hatena.ne.jp', '56 Valley Edge Court', 'bS8<t7ySuM7', '2023/10/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH626518', 'Lari Skace', 'F', '2001/06/23', '0355064251614', '1974/08/14', 'Indonesia', '0013501945', 'lskace3f@whitehouse.gov', '79 Artisan Crossing', 'uT3{8p"a$=FTSQ1p', '2009/03/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH862046', 'Carlyn Sabathe', 'M', '1991/02/02', '0844391851100', '2000/10/20', 'Poland', '0319931207', 'csabathe3g@soundcloud.com', '2492 Troy Avenue', 'hZ2,5f5Qs1v,7i', '2004/01/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH454423', 'Amalea Bellringer', 'M', '1963/04/10', '0158961378295', '2006/05/03', 'China', '0440226735', 'abellringer3h@vistaprint.com', '2251 Fallview Way', 'nB6<w6yp', '2013/07/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH221463', 'Reeva Dowry', 'M', '1947/09/16', '0418964491391', '2020/03/04', 'Ethiopia', '0066861945', 'rdowry3i@berkeley.edu', '6856 Arizona Junction', 'oM3,gIZQ', '2009/12/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH243604', 'Roth Brownbridge', 'F', '1991/07/28', '0408590337876', '1965/11/11', 'China', '0781382415', 'rbrownbridge3j@hp.com', '67646 Carioca Terrace', 'rX3<2''(!Pa''G|c9z', '1996/05/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH225914', 'Nanette Macallam', 'F', '1949/05/05', '0710977715618', '2017/10/14', 'Venezuela', '0819760415', 'nmacallam3k@abc.net.au', '1775 Mitchell Alley', 'iS6|Ir7zH''wj~8S', '2024/01/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH817290', 'Rodie Elgood', 'M', '1960/08/16', '0895559508700', '1983/04/18', 'China', '0595048033', 'relgood3l@shop-pro.jp', '16 Troy Lane', 'sU2<&zkbm', '2001/02/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH396109', 'Des Goodinson', 'M', '1988/03/08', '0522606628271', '2020/09/15', 'China', '0559735905', 'dgoodinson3m@cbc.ca', '763 Morrow Terrace', 'hG0%4I1ehpht''/', '1988/11/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH823647', 'Kenyon Janny', 'F', '1954/02/11', '0964845446458', '2001/07/09', 'Portugal', '0315365573', 'kjanny3n@tuttocitta.it', '735 Maple Wood Point', 'eA5`S''O#', '2008/01/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH044397', 'Wallis Picton', 'M', '1977/03/24', '0213603632994', '2005/07/03', 'Portugal', '0973801196', 'wpicton3o@arizona.edu', '8 La Follette Junction', 'tE4>8<%SyJ', '1993/07/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH407699', 'Dolf Lauderdale', 'F', '1987/01/18', '0517168214039', '1996/04/08', 'Indonesia', '0041408977', 'dlauderdale3p@oaic.gov.au', '000 Portage Junction', 'sB1$1Z65FQn', '1971/04/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH281824', 'Bidget Pooke', 'F', '2000/12/29', '0684746323062', '2020/05/27', 'Uzbekistan', '0816904781', 'bpooke3q@altervista.org', '46 Ridgeview Parkway', 'xD2@8C.\D@#)', '1996/01/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH335228', 'Mireielle Bradbury', 'F', '1996/05/27', '0589208895283', '1990/11/18', 'China', '0707205407', 'mbradbury3r@ftc.gov', '6581 Talisman Park', 'lD7<=~klG\_w#"', '1979/08/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH457377', 'Birk Rickard', 'F', '1996/08/22', '0004198025601', '1968/09/03', 'Ukraine', '0022990493', 'brickard3s@networksolutions.com', '5616 Jackson Terrace', 'dI1)lH.ph>>w', '1970/04/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH241296', 'Bobbye Dogg', 'F', '1974/03/24', '0171710853780', '2005/01/02', 'United States', '0375227349', 'bdogg3t@npr.org', '5909 Cottonwood Court', 'wH8@<=LO<z/', '2009/02/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH290459', 'Jordana Napthine', 'F', '1997/08/14', '0937499787132', '2019/02/12', 'Sweden', '0638010254', 'jnapthine3u@163.com', '5334 Meadow Valley Place', 'oV5&#KiPI', '2011/08/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH653566', 'Anna-diana Yepiskopov', 'M', '1949/12/11', '0970691747221', '2009/10/19', 'Russia', '0377113556', 'ayepiskopov3v@ftc.gov', '29 Coolidge Circle', 'nJ0}c5S!', '2004/05/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH095865', 'Launce MacKay', 'F', '1976/08/24', '0016566926134', '1992/10/12', 'Brazil', '0358112489', 'lmackay3w@twitpic.com', '4686 West Circle', 'hR7}tgX@i', '1976/01/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH283594', 'Eolanda Hoyte', 'F', '1973/07/24', '0069078026365', '2014/05/13', 'Ukraine', '0066189246', 'ehoyte3x@twitpic.com', '5 Sachtjen Center', 'dV3+6KA|ny', '2014/07/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH553797', 'Rainer Fleote', 'M', '1974/11/05', '0805161135401', '2009/08/09', 'China', '0209326591', 'rfleote3y@nature.com', '7 Ryan Terrace', 'yI6$T{Hh@6I<.', '2022/07/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH056342', 'Elmore Drable', 'M', '1984/09/12', '0159705736896', '1986/03/22', 'Indonesia', '0654018512', 'edrable3z@cloudflare.com', '4906 Mockingbird Junction', 'aY1@j@&I', '1976/03/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH087105', 'Alfi Piecha', 'F', '1963/03/22', '0726110325590', '2021/12/13', 'Republic of the Congo', '0496231277', 'apiecha40@timesonline.co.uk', '506 Browning Plaza', 'fT9!CvA30*~_z.t', '1992/01/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH063543', 'Raimund Chainey', 'M', '2002/04/03', '0982267153825', '1968/06/12', 'Russia', '0930389373', 'rchainey41@indiatimes.com', '88182 Dexter Circle', 'dG9/D>WC''99$7', '2019/04/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH857577', 'Danielle Chippindall', 'M', '1996/08/17', '0815653353082', '1994/01/01', 'China', '0753165439', 'dchippindall42@imgur.com', '8 Old Gate Drive', 'bB8=3*.2zg8C''', '1963/07/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH647704', 'Maribelle Tortoise', 'F', '1954/11/09', '0620965190063', '2020/01/15', 'China', '0646168333', 'mtortoise43@google.com', '901 Homewood Point', 'nY2<5\BXZIr7''', '2023/09/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH805372', 'Babbie Messenger', 'F', '1992/06/23', '0820520145652', '2001/01/29', 'Honduras', '0722837775', 'bmessenger44@theglobeandmail.com', '6 Center Place', 'bF3~u''\vowKJ''f3>', '1985/06/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH903096', 'Ardelle Burlingham', 'M', '1955/01/30', '0157918577999', '1974/04/06', 'Philippines', '0839455425', 'aburlingham45@symantec.com', '1 Sheridan Crossing', 'wQ9|)K<q#', '1988/05/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH643225', 'Isaac Gibbonson', 'F', '1987/11/13', '0303955295380', '1967/06/16', 'France', '0816037247', 'igibbonson46@stumbleupon.com', '7678 Village Green Trail', 'iH0@3GXjELD|/rj', '2007/06/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH016282', 'Faythe Hayman', 'M', '1961/07/10', '0118983814494', '1965/04/19', 'Russia', '0575614213', 'fhayman47@tiny.cc', '36601 Old Gate Street', 'nZ7)xGM8C6n"d`J', '2000/05/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH748649', 'Carla Gallifont', 'M', '1968/01/13', '0243277130768', '1976/11/24', 'Poland', '0442166936', 'cgallifont48@twitpic.com', '0992 Shasta Parkway', 'xF1(5s68I2.', '1963/07/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH557590', 'Dolores Ineson', 'F', '2002/03/20', '0107313099626', '2013/02/17', 'Indonesia', '0616552208', 'dineson49@tiny.cc', '39815 Orin Road', 'mG3/~u0RVNU@', '1983/05/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH176932', 'Britta Rigeby', 'M', '1989/06/17', '0565237378557', '1968/12/08', 'Argentina', '0567622413', 'brigeby4a@squarespace.com', '7830 Aberg Park', 'bP6&JADYY', '1983/06/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH120054', 'Korella Ratter', 'M', '1945/03/29', '0024357516620', '1997/01/29', 'China', '0650790234', 'kratter4b@boston.com', '5 Karstens Street', 'oB3%.3UT+3', '1965/05/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH987796', 'Langsdon Ghilks', 'F', '1977/03/05', '0774105643588', '1980/11/17', 'Burkina Faso', '0502926800', 'lghilks4c@godaddy.com', '9 Hanover Alley', 'jX1@hJO{0', '1976/04/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH526686', 'Kevyn Cammiemile', 'M', '1966/09/22', '0352280535913', '2012/02/08', 'France', '0649802959', 'kcammiemile4d@dailymotion.com', '08 Victoria Lane', 'mX1`t+)$\OY', '2020/10/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545522', 'Boigie Mathan', 'M', '2000/03/29', '0942278731479', '1987/12/07', 'Philippines', '0198110643', 'bmathan4e@globo.com', '3906 Prairieview Way', 'uN0*4Kd8#!U', '1989/06/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH980984', 'Olga Sparwell', 'M', '1955/04/24', '0105143308044', '2008/10/13', 'Indonesia', '0927499626', 'osparwell4f@seesaa.net', '4 Park Meadow Junction', 'iU9\Z._t!)>.F=', '2000/09/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH190995', 'Byrle Baudins', 'M', '2000/08/04', '0100816061144', '1965/07/17', 'Indonesia', '0335182197', 'bbaudins4g@shareasale.com', '91 Sutherland Terrace', 'zQ1&$@dE?qb', '2021/11/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH460998', 'Shawna Smerdon', 'M', '1955/08/18', '0619148048003', '2024/04/06', 'Indonesia', '0294084123', 'ssmerdon4h@nifty.com', '5784 Golden Leaf Drive', 'eH5/LF+K', '1964/12/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH177395', 'Janot Punt', 'M', '1978/11/30', '0982352059924', '1981/09/22', 'Indonesia', '0843947220', 'jpunt4i@prweb.com', '609 7th Alley', 'dL9@p8dl*V9y~', '2016/06/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH993336', 'Karita Narducci', 'F', '1988/06/10', '0880534107117', '1991/07/05', 'Estonia', '0112990130', 'knarducci4j@prlog.org', '06 Declaration Court', 'wV8&xf.@/k?8ZR{', '1970/09/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH491555', 'Edeline Gutch', 'M', '1997/04/20', '0173940664648', '1985/05/10', 'Indonesia', '0017893784', 'egutch4k@nymag.com', '470 Continental Drive', 'vC2/noc>ka\', '1967/12/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374822', 'Farley Brilon', 'M', '1971/11/10', '0332186600118', '2010/11/28', 'Senegal', '0789499231', 'fbrilon4l@feedburner.com', '88419 Cascade Center', 'qH4=J''m$g,ElY', '2008/04/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH407901', 'Hendrick McGeachie', 'M', '1956/03/23', '0900841858736', '2003/12/12', 'China', '0489830781', 'hmcgeachie4m@squarespace.com', '3 Bartillon Trail', 'yA2"eRoh?HdYO', '1971/04/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH098418', 'Barde Shopcott', 'M', '1984/12/22', '0857252980170', '2005/08/05', 'Burkina Faso', '0825151693', 'bshopcott4n@cnbc.com', '51 Mcbride Park', 'hF5/<TPcJj', '1979/10/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH386338', 'Avril Harkins', 'M', '1955/09/20', '0952823241636', '2005/12/01', 'Thailand', '0735806937', 'aharkins4o@dmoz.org', '35 Corscot Park', 'yR2&G.uRF(Ih.~', '2022/01/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH714662', 'Fredric Furnell', 'F', '1947/12/22', '0022084214204', '2018/12/03', 'China', '0691540130', 'ffurnell4p@amazon.co.uk', '68 Division Parkway', 'tZ8#L+GCGb|6.GW5', '1963/05/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH483866', 'Raddy Train', 'F', '1987/04/14', '0522263846211', '2011/07/04', 'Russia', '0526453991', 'rtrain4q@google.com.hk', '88 Blaine Way', 'rQ5$uhm0+VL<hl}', '2003/06/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH153049', 'Betta McOrkil', 'F', '1956/04/01', '0111681192594', '2017/01/23', 'China', '0062190036', 'bmcorkil4r@cbc.ca', '63 Oakridge Pass', 'iZ1\=U8|3N1tVZp', '1988/03/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH398842', 'Elna Tayloe', 'M', '1991/01/19', '0736016394803', '1980/05/14', 'Greece', '0310463788', 'etayloe4s@themeforest.net', '4 Memorial Terrace', 'mX4"LTP\1zz', '1966/08/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH621641', 'Judah Blewitt', 'M', '1984/04/13', '0465673971557', '2012/12/12', 'Indonesia', '0869623750', 'jblewitt4t@state.tx.us', '813 Old Shore Trail', 'iX6"gCaX?', '2010/05/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH690162', 'Phyllida Peplow', 'M', '1983/08/02', '0154580588068', '1993/09/12', 'Philippines', '0348943783', 'ppeplow4u@netlog.com', '571 Spaight Point', 'gR1<SX@?rYK~4tF@', '1992/05/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084145', 'Inga Wasielewski', 'F', '1995/09/21', '0133187670055', '2004/07/23', 'Philippines', '0662063723', 'iwasielewski4v@nih.gov', '57 Veith Place', 'aU7*8*`w.lPY', '1976/04/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH707432', 'Opal Petchell', 'M', '1976/06/05', '0388357858806', '2023/01/29', 'Brazil', '0317603892', 'opetchell4w@infoseek.co.jp', '3 Eggendart Drive', 'kZ6}nk+uG&sQ', '1968/07/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH414310', 'Vivianna Carr', 'M', '1979/03/02', '0562905812034', '2000/03/29', 'China', '0975339721', 'vcarr4x@hubpages.com', '896 Little Fleur Drive', 'uA4,iTqx', '1995/03/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH750553', 'Freddie Blemen', 'F', '2002/01/22', '0620158139181', '1993/05/29', 'United States', '0746252174', 'fblemen4y@home.pl', '25242 Drewry Drive', 'vV3+''R@=+O', '2015/01/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH811058', 'Staffard de Amaya', 'M', '1973/05/12', '0393265183428', '1984/05/06', 'Peru', '0919375202', 'sde4z@bandcamp.com', '1590 Glendale Park', 'rP0@y"exb', '2012/08/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH896229', 'Carmon Panther', 'F', '1960/04/16', '0586492148977', '1970/03/17', 'China', '0202934816', 'cpanther50@cnet.com', '14003 Hermina Street', 'fN8/v`gHw%', '1978/12/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH791400', 'Reginauld Skipperbottom', 'F', '1956/05/10', '0011480367977', '2017/04/12', 'Egypt', '0838161444', 'rskipperbottom51@about.com', '40 Esker Parkway', 'dB4(L3pe<Q?/}sG', '2008/02/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH564833', 'Jocelyn Lindwall', 'M', '1990/09/11', '0766721296175', '2001/10/21', 'China', '0701890128', 'jlindwall52@privacy.gov.au', '2 Saint Paul Parkway', 'aT3_JWR{CCN&Jx"', '1979/01/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH480291', 'Federica Jossum', 'F', '1977/01/24', '0752533898158', '2002/05/05', 'Indonesia', '0957316335', 'fjossum53@gmpg.org', '9 Victoria Avenue', 'vD0*8\}.4>e_7p', '1971/07/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH757591', 'Mady McNirlin', 'M', '2001/03/26', '0087335567768', '1997/11/04', 'Bahrain', '0982996985', 'mmcnirlin54@oaic.gov.au', '2 Drewry Center', 'iU9=|&\fF?', '1988/03/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH362854', 'Nathalia Marwood', 'F', '1991/01/16', '0117512498427', '2023/10/17', 'Syria', '0207350340', 'nmarwood55@theguardian.com', '9 Oak Point', 'lM4"%$+%T55t6Puy', '1980/03/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH375073', 'Elbertina Ousbie', 'F', '1976/09/17', '0568986000207', '2003/09/23', 'Indonesia', '0334025545', 'eousbie56@si.edu', '1483 Eliot Junction', 'nB1*Ii1|=Z8.', '2016/12/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH254916', 'Michelle Goggins', 'F', '2000/10/07', '0829288260834', '1995/09/20', 'Netherlands', '0902297692', 'mgoggins57@bloglovin.com', '9 Laurel Avenue', 'fC4}.\Pc', '1996/08/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH453142', 'Rudolf Albasini', 'M', '1990/02/13', '0041643744368', '2006/06/20', 'Germany', '0360297871', 'ralbasini58@foxnews.com', '7 Karstens Street', 'yW2`{Pq9r@(+', '2006/03/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH549396', 'Jorie Holworth', 'F', '1996/02/19', '0009232440530', '2008/04/21', 'Indonesia', '0893950612', 'jholworth59@bloglovin.com', '30575 Maryland Alley', 'jK2|S~R&@S<6', '2006/01/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH577751', 'Renell Bowater', 'F', '1979/02/09', '0565534840132', '2018/10/05', 'Brazil', '0372067795', 'rbowater5a@prnewswire.com', '82162 Arapahoe Lane', 'lA6?//P((A', '1984/11/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH456224', 'Jackson Dorney', 'M', '1957/03/02', '0294214703937', '1981/12/08', 'Thailand', '0493971838', 'jdorney5b@topsy.com', '3 Schurz Street', 'mX1@DrJ/2g', '1968/04/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH518463', 'Wallis Lopez', 'M', '1945/09/07', '0108478687103', '2022/01/12', 'Portugal', '0921549722', 'wlopez5c@usnews.com', '71523 Lien Point', 'yF6#c6./NJ', '2018/07/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH798971', 'Alana Powling', 'M', '1972/02/18', '0418863079953', '2013/05/16', 'Sweden', '0932953270', 'apowling5d@xrea.com', '65 Scofield Avenue', 'mW8+eU3wM7', '1999/09/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH491026', 'Tamra Lowcock', 'M', '1965/03/20', '0476566245258', '2016/09/17', 'Indonesia', '0774112168', 'tlowcock5e@ucoz.com', '771 Mayfield Point', 'tR8<NnZOm', '1975/06/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH271569', 'Richardo Hasson', 'F', '1948/05/02', '0077941900623', '2008/05/23', 'China', '0241538606', 'rhasson5f@umn.edu', '52141 Walton Pass', 'oT9%O`,r', '1983/05/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH936121', 'Dominica Bagnold', 'F', '1967/02/15', '0987148836062', '1995/01/03', 'Sweden', '0201136768', 'dbagnold5g@craigslist.org', '94332 Green Street', 'mZ5>T/<%t', '2023/04/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH646823', 'Ulises Heardman', 'F', '1976/09/19', '0280568778523', '1969/08/08', 'China', '0831878647', 'uheardman5h@merriam-webster.com', '7132 Hauk Hill', 'gI9}a0+$nlF', '2023/02/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH205161', 'Morty Boulde', 'F', '1974/10/29', '0753434553867', '2002/01/23', 'United States', '0344972341', 'mboulde5i@dell.com', '69 Rowland Lane', 'tB1"BqxsJA8Xj(y', '1973/04/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH425726', 'Alane Crossingham', 'M', '1992/09/25', '0377050795173', '1979/04/19', 'Colombia', '0437791151', 'acrossingham5j@meetup.com', '044 Anhalt Alley', 'rO6~*.8w@', '2005/11/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH492275', 'Howie Bortolussi', 'M', '1980/08/26', '0136493779766', '2003/11/07', 'Venezuela', '0431720129', 'hbortolussi5k@hp.com', '4 Ilene Drive', 'mO1*)qonXc1z*Ixx', '2004/09/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH592532', 'Carlynne O'' Gara', 'M', '1955/12/01', '0225542688722', '1982/02/15', 'Guatemala', '0343365463', 'co5l@sitemeter.com', '0509 Pankratz Alley', 'zV9)13Z8kT%F.6Qv', '1976/05/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH980649', 'Cinda Hobgen', 'F', '1984/10/07', '0787903881099', '1972/08/06', 'Peru', '0810101014', 'chobgen5m@mac.com', '1154 Buena Vista Avenue', 'mK3@5cXEgCu7?', '2012/01/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH409572', 'Brig Bolens', 'F', '1985/05/06', '0531148583852', '2020/03/26', 'China', '0982555443', 'bbolens5n@imdb.com', '3983 Bay Avenue', 'qJ9!{{pOT$va/', '1998/08/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH907558', 'Kristin Oswald', 'M', '1950/05/23', '0280107467228', '2010/11/13', 'Czech Republic', '0471886935', 'koswald5o@nytimes.com', '09152 Ohio Way', 'aI6&3s=E=NH|?I22', '1992/11/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH910997', 'Oliver De Roberto', 'F', '2001/03/22', '0199960549551', '2019/04/22', 'Madagascar', '0995666013', 'ode5p@nature.com', '09 Golf View Way', 'bR4+2fcZ', '1965/03/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH057855', 'Valentino Spruce', 'F', '1954/11/11', '0739977262647', '1970/12/25', 'Belgium', '0917636974', 'vspruce5q@angelfire.com', '5 Reindahl Alley', 'vX8/Fw|cN', '1987/12/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH597520', 'Kayne Grumell', 'M', '1993/11/07', '0063349941051', '2018/04/22', 'Indonesia', '0128604641', 'kgrumell5r@europa.eu', '62 Sugar Plaza', 'zR7`IfY#i', '2010/06/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH086552', 'Dyann Clardge', 'M', '1988/03/31', '0915213122178', '1993/07/01', 'Mexico', '0374169761', 'dclardge5s@over-blog.com', '90 Messerschmidt Park', 'zM6''(2,9&S.f', '1993/03/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH585669', 'Ichabod Shanks', 'F', '1997/07/09', '0062664694635', '2004/10/20', 'Brazil', '0440583824', 'ishanks5t@hubpages.com', '10874 Gerald Point', 'gI9~q~(kwh*B\\Zr', '1967/05/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH547008', 'Lombard Brewitt', 'M', '1950/10/09', '0384827511161', '2020/06/04', 'Nicaragua', '0236480939', 'lbrewitt5u@psu.edu', '9079 Debs Pass', 'cB5)a*PH,O"dc9', '1989/09/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH540081', 'Henrik Rubinowitz', 'M', '1990/09/19', '0178726426447', '1991/01/14', 'Indonesia', '0370919353', 'hrubinowitz5v@xrea.com', '3 Scoville Court', 'fH0}=deRg', '1981/06/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH782287', 'Clyve Aronovitz', 'M', '1956/10/01', '0409358186570', '1998/11/20', 'Guatemala', '0212952681', 'caronovitz5w@linkedin.com', '24 Morningstar Junction', 'mO9.fiOps4SH', '2002/02/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH971165', 'Anabelle Charlin', 'M', '1991/01/11', '0333054426366', '2006/02/28', 'United States', '0238988154', 'acharlin5x@twitpic.com', '79 Hudson Avenue', 'iM4&Ps=0.7!>%Ly/', '1994/11/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH796829', 'Gloria Dickins', 'M', '1965/04/18', '0832506092105', '2005/03/05', 'Brazil', '0036407196', 'gdickins5y@ucsd.edu', '64960 Reindahl Junction', 'vH9.od9X=', '2000/07/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH716623', 'Barri Rowbury', 'F', '1964/03/10', '0592286683890', '1999/10/08', 'Russia', '0376227133', 'browbury5z@theglobeandmail.com', '305 Mayfield Trail', 'mR1+?{JQ', '1991/09/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH018367', 'Beatrisa Robins', 'F', '1956/04/08', '0004278736570', '1972/07/11', 'Portugal', '0110153585', 'brobins60@gnu.org', '168 Arkansas Place', 'nI3*"&vrsbF8).', '2000/06/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH101740', 'Purcell Cagan', 'F', '1993/06/01', '0659320332527', '1991/03/24', 'Canada', '0247199378', 'pcagan61@yahoo.com', '7 Drewry Drive', 'yC8+y>iEE>"@4Di', '2003/01/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH045726', 'Gabriella Risson', 'M', '1990/07/12', '0092033704268', '1988/02/28', 'China', '0215389329', 'grisson62@yale.edu', '91 Melody Pass', 'qY2{''f%bDk`iV', '1979/09/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH558152', 'Rosemaria Rubinowitz', 'M', '1973/12/29', '0629852635248', '1998/02/18', 'China', '0691216511', 'rrubinowitz63@hp.com', '032 Sunnyside Avenue', 'qQ2_m5rKov4rJ709', '2004/05/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH380827', 'Silvio Yoodall', 'F', '1972/10/01', '0816196849058', '2006/12/12', 'Czech Republic', '0594765479', 'syoodall64@hao123.com', '5189 Mosinee Parkway', 'kQ0/T?2ir&HK', '2020/01/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH995610', 'Kirsteni Spiby', 'F', '1967/06/12', '0925673149037', '1973/03/20', 'China', '0349044034', 'kspiby65@yahoo.com', '97122 Loeprich Circle', 'iQ2#sWWz0$1v''1k', '1965/11/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH425172', 'Hyatt Amsden', 'F', '1965/06/12', '0828715433226', '2002/07/28', 'Philippines', '0989456334', 'hamsden66@sina.com.cn', '04 Springview Plaza', 'kZ2{Hj6?9GX#I', '2013/07/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH134882', 'Aidan Porcher', 'M', '1992/05/22', '0382065192611', '1978/06/06', 'China', '0536290464', 'aporcher67@cpanel.net', '56773 Montana Lane', 'zC9")/{bD&D!x\', '1968/09/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH992165', 'Cheri Acock', 'M', '1956/02/01', '0458213828692', '2014/03/06', 'Indonesia', '0576025290', 'cacock68@angelfire.com', '7 Jay Junction', 'yJ1?,W2uXYd', '1977/04/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH236596', 'Grantham Deniskevich', 'M', '1992/02/10', '0193227728159', '2017/08/01', 'Ukraine', '0669909387', 'gdeniskevich69@alexa.com', '411 Toban Way', 'jD6.Y/j3G', '1987/03/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH085398', 'Flin Burdett', 'F', '1964/02/18', '0582504055382', '1992/11/07', 'Czech Republic', '0712914994', 'fburdett6a@altervista.org', '648 Rutledge Point', 'zZ8>|{\!.jMyo', '1997/03/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH975326', 'Laney Penke', 'F', '1972/02/16', '0215833381081', '1992/09/14', 'Japan', '0890953845', 'lpenke6b@g.co', '3 Mccormick Road', 'aU7}<J@{kW1q', '1991/02/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH599858', 'Doti Egell', 'F', '1960/05/10', '0727399171403', '1983/06/19', 'China', '0275219521', 'degell6c@wufoo.com', '91 Carpenter Lane', 'oT6@eH.8c', '1999/10/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH984343', 'Hamlen Espada', 'M', '1976/12/06', '0558353389103', '1977/11/01', 'Philippines', '0315827654', 'hespada6d@businesswire.com', '66 Pleasure Point', 'nF8_N&4ye.8)u~Yn', '1984/07/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH260266', 'Noak Millins', 'M', '1986/01/18', '0014133166129', '2018/10/25', 'Indonesia', '0114877725', 'nmillins6e@weibo.com', '28 Coleman Parkway', 'sS6%6JlEO!(T"5M', '1963/09/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH814108', 'Leonid Bendall', 'F', '1961/12/18', '0540701408040', '1984/06/26', 'Peru', '0229330939', 'lbendall6f@elegantthemes.com', '73694 Melrose Trail', 'uR9+JDT,vuf!PCo', '2023/09/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH792986', 'Bartholemy Clingoe', 'M', '1989/08/19', '0211873734954', '1981/07/05', 'Indonesia', '0884409259', 'bclingoe6g@comsenz.com', '5 Manitowish Alley', 'xP6?%i"t!VQg', '1978/02/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH700174', 'Karlik Dominik', 'M', '1973/12/31', '0264382004508', '2009/03/22', 'Russia', '0447248507', 'kdominik6h@yelp.com', '9367 Maywood Alley', 'fF1+|FHaT', '2005/08/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH724673', 'Nanete Sighart', 'F', '1981/12/16', '0684917771176', '2011/02/15', 'Philippines', '0423430817', 'nsighart6i@sciencedirect.com', '28204 Cordelia Drive', 'aR6<a.Ar#s', '2018/09/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH213357', 'Ashby Dales', 'M', '1954/09/15', '0564084628819', '1989/09/28', 'Indonesia', '0797050105', 'adales6j@paypal.com', '22 Magdeline Park', 'lW9,_u@"<63R7Yf\', '2023/05/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH412780', 'Mercie Whitlock', 'M', '1991/05/28', '0897670229291', '1979/01/05', 'Czech Republic', '0280632795', 'mwhitlock6k@blogs.com', '6 Ilene Street', 'zJ0{IDgUHbJ{k', '2001/01/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH227910', 'Brody Tretter', 'M', '1966/06/20', '0099318916906', '1974/05/12', 'China', '0299322319', 'btretter6l@cpanel.net', '9366 Moland Street', 'sO9+5g<,,a|raWyQ', '2003/11/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH031990', 'Merilee Sciusscietto', 'M', '1954/01/06', '0873057320583', '1971/05/11', 'Russia', '0376460272', 'msciusscietto6m@myspace.com', '39 Service Street', 'kV8@G?@Hg&i""}kE', '1992/11/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH293180', 'Izak Flockhart', 'M', '1956/04/29', '0615845836053', '2018/10/14', 'China', '0413714001', 'iflockhart6n@imdb.com', '61 Warner Crossing', 'nF3~rN"Ef#`', '1983/07/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH088786', 'Maxy Klagge', 'F', '1982/09/26', '0002883284939', '1988/07/18', 'United States', '0259150183', 'mklagge6o@seattletimes.com', '0 Nobel Alley', 'vZ5~i>487#Z!', '1975/02/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH978474', 'Robina Cason', 'F', '1984/05/21', '0319796159705', '2011/04/11', 'Philippines', '0432135511', 'rcason6p@unicef.org', '8 Muir Crossing', 'fD7?\tMx9dX#?w#', '1967/05/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084846', 'Jannel Ettles', 'F', '1981/11/06', '0903816850727', '1964/09/21', 'Philippines', '0215813206', 'jettles6q@google.es', '4322 Roxbury Way', 'fX1<p@%D&M>{k*', '1978/06/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH965543', 'Juliann Bachelor', 'F', '1961/05/05', '0695965679483', '1975/02/13', 'Philippines', '0212882266', 'jbachelor6r@state.gov', '1 Forest Dale Hill', 'oO0?dFEQ''tVx', '1979/04/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH710303', 'Leeland Stranaghan', 'F', '1972/02/26', '0040516775971', '2007/06/23', 'Indonesia', '0007000124', 'lstranaghan6s@walmart.com', '1161 Knutson Place', 'uD2/0!`JeUt6', '1970/05/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH230361', 'Edmon Rainford', 'M', '1960/09/03', '0564302641040', '2003/07/04', 'Pakistan', '0159522696', 'erainford6t@rediff.com', '894 Glendale Court', 'wS8*La%`fK{?Pn%p', '2001/03/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH512913', 'Lion Tissell', 'M', '1969/02/23', '0901118158125', '1996/03/01', 'Georgia', '0708634343', 'ltissell6u@digg.com', '914 Arizona Court', 'lU9.nK`pN3', '2019/06/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH231668', 'Cyndia Ambroisin', 'M', '1948/11/22', '0957831655524', '1966/11/23', 'Brazil', '0454838741', 'cambroisin6v@rediff.com', '625 West Lane', 'bN8%<KeW', '1973/04/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH336007', 'Egan Caverhill', 'F', '1966/09/04', '0413134650553', '1983/11/25', 'China', '0389861762', 'ecaverhill6w@twitter.com', '258 Cherokee Plaza', 'hK2%{yy6ck', '2001/10/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH614628', 'Findley Bodsworth', 'M', '1980/11/24', '0207444802024', '1970/09/08', 'China', '0463993554', 'fbodsworth6x@bloomberg.com', '1962 Kingsford Plaza', 'bU0?|8%_1q+(x', '1999/03/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH370775', 'Henryetta Papes', 'F', '1952/05/26', '0650583129936', '1988/11/20', 'Albania', '0194684845', 'hpapes6y@wix.com', '60607 Myrtle Hill', 'tG1\88)ZAM}5=,', '2013/09/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH469917', 'Eveleen Lanbertoni', 'M', '1995/11/23', '0186493608757', '2023/09/09', 'Greece', '0988478277', 'elanbertoni6z@noaa.gov', '5 Forest Run Avenue', 'yJ3}IH+r)q$by%', '2007/03/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH062247', 'Jewelle Heading', 'M', '1976/02/17', '0674072034895', '1966/08/16', 'Indonesia', '0880802748', 'jheading70@gnu.org', '98 Monica Crossing', 'bB7&O''g21', '2019/01/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH349897', 'Jordan Chatres', 'F', '1985/09/10', '0853039938298', '2009/03/25', 'China', '0471655973', 'jchatres71@sakura.ne.jp', '829 Pond Drive', 'rK5.vqu0x`QIp$Gl', '1986/11/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH398851', 'Carmella Vincent', 'F', '1983/04/21', '0279058105365', '1991/09/14', 'Micronesia', '0398805864', 'cvincent72@weather.com', '02253 Hayes Center', 'wQ3!{2+J(jK', '1998/09/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH460521', 'Cross Birtle', 'F', '1964/02/24', '0762486215172', '1983/04/16', 'Netherlands', '0378771876', 'cbirtle73@barnesandnoble.com', '0 Bay Center', 'wG5*XMTHX', '1995/01/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH431206', 'Parnell Oldroyde', 'M', '1977/05/13', '0387518047720', '2019/05/24', 'Czech Republic', '0337746320', 'poldroyde74@thetimes.co.uk', '82462 Westport Circle', 'cE7+q/~D*OdR>0Pk', '1981/10/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH121413', 'Yehudi Shimmings', 'M', '1955/05/13', '0442891264566', '2022/04/08', 'China', '0700365550', 'yshimmings75@tripod.com', '46761 Bayside Hill', 'oB9>`_)Mk<}$Q#e', '1968/12/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH667915', 'Francklin Kembry', 'M', '1958/03/10', '0494719762336', '1966/04/08', 'Indonesia', '0304729525', 'fkembry76@miibeian.gov.cn', '690 Darwin Hill', 'dN9.AvbNch*', '2001/03/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH611663', 'Wenona Fruchter', 'F', '1981/01/15', '0808520999785', '2022/02/02', 'Guatemala', '0604831684', 'wfruchter77@slate.com', '18 Sherman Avenue', 'gV4`q`yN+', '1972/10/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH044747', 'Nadya Klugel', 'F', '1984/03/03', '0395469019467', '1988/03/13', 'Finland', '0876673065', 'nklugel78@vistaprint.com', '3531 International Lane', 'uR3*\Db0R"', '1990/03/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH546066', 'Monti Viveash', 'M', '1986/08/17', '0904532220897', '2014/08/17', 'Indonesia', '0911075126', 'mviveash79@shareasale.com', '1 Crowley Pass', 'kL4/WyZ9', '1976/07/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH441817', 'Hamnet Stockill', 'F', '1981/10/12', '0947957118499', '2006/05/20', 'Japan', '0237544532', 'hstockill7a@odnoklassniki.ru', '18279 Butterfield Street', 'vA4(T<"o9q+gN!um', '1968/08/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH625033', 'Langston Soar', 'M', '1988/02/03', '0592683276163', '1966/06/25', 'Russia', '0226227189', 'lsoar7b@sina.com.cn', '67176 Scofield Street', 'dG6}6VxwwY0M~pGo', '1969/03/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH904387', 'Lew Muldowney', 'M', '2001/12/17', '0142296645705', '1996/07/30', 'Peru', '0960249868', 'lmuldowney7c@uol.com.br', '560 Mcbride Terrace', 'fF6{2LUc', '1993/07/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH322037', 'Yuri Cuesta', 'M', '1998/01/06', '0974549784456', '2022/01/04', 'Pakistan', '0937690768', 'ycuesta7d@slashdot.org', '77392 Burrows Street', 'hM5?D?J<x~>E', '2001/03/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH028582', 'Anton Dyka', 'F', '1953/05/10', '0094061047248', '1998/05/28', 'China', '0801621945', 'adyka7e@yellowpages.com', '878 Jackson Parkway', 'mG8%|UbeT}>OjW', '2024/02/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH576265', 'Christian Slafford', 'M', '1948/08/14', '0285928597383', '1974/11/29', 'China', '0477520524', 'cslafford7f@businessinsider.com', '2904 Mitchell Junction', 'qX2{qzQK_$Nb6''/S', '2000/04/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH669019', 'Kylie Messer', 'M', '1967/03/02', '0295249288161', '2020/12/04', 'Czech Republic', '0404626596', 'kmesser7g@mit.edu', '14 Artisan Junction', 'sS5+e2iacr|HS5jB', '1986/10/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH791545', 'Demeter Eglinton', 'M', '1949/11/01', '0311632813359', '1978/10/27', 'Sweden', '0376487607', 'deglinton7h@usnews.com', '8 Bartelt Junction', 'fB4#,''@F/`KH6G)', '2007/02/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH282109', 'Beltran Ranscombe', 'M', '1982/08/12', '0071744992737', '2009/09/11', 'China', '0881326918', 'branscombe7i@irs.gov', '67 Homewood Terrace', 'pG2#s("1D~)n', '2012/02/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH847284', 'Odessa Jelks', 'M', '1965/11/07', '0958047268160', '1999/04/24', 'Ivory Coast', '0141268085', 'ojelks7j@admin.ch', '31 Ohio Plaza', 'cZ5`<_=K_(=X9', '1964/12/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH390926', 'August Guterson', 'M', '1988/10/18', '0350968929227', '2007/09/27', 'Kuwait', '0988883220', 'aguterson7k@nationalgeographic.com', '85 Mallory Point', 'xZ2!.Z7I$%Q6l', '2013/11/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH828458', 'Antin McMenamy', 'F', '1997/04/12', '0336031332841', '2002/04/23', 'China', '0643739954', 'amcmenamy7l@de.vu', '0 Maywood Circle', 'eI2/Fu''y', '1972/02/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH092022', 'Abraham Nappin', 'F', '1996/07/10', '0059331114154', '1995/02/18', 'Brazil', '0898589655', 'anappin7m@patch.com', '37745 Merrick Road', 'kG2>1yZde\%$+VI', '2009/02/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH816691', 'Martin Laurenson', 'M', '1948/07/30', '0743411969253', '1977/07/14', 'Poland', '0848371995', 'mlaurenson7n@fastcompany.com', '044 Miller Avenue', 'mI3}#J71\(!}4gC', '1982/07/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH773307', 'Mirabel Grinyov', 'F', '1950/10/08', '0004158806120', '1978/05/05', 'Finland', '0626173308', 'mgrinyov7o@purevolume.com', '1077 Surrey Place', 'nB6.Qc+u\k#', '2012/07/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH479521', 'Marilee Pundy', 'F', '1991/02/20', '0255143375783', '1966/12/31', 'Argentina', '0414563237', 'mpundy7p@vkontakte.ru', '95 Eliot Hill', 'zL9.>KX=dB{tU__A', '1979/08/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH317980', 'Barnard Beddingham', 'M', '1991/05/22', '0443599540175', '1989/07/08', 'Malaysia', '0425744243', 'bbeddingham7q@chicagotribune.com', '72 Forest Court', 'tM0@X}1&bhy', '2019/03/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH177678', 'Lanae Christene', 'F', '1989/07/10', '0111942388343', '1975/03/21', 'Azerbaijan', '0015500570', 'lchristene7r@booking.com', '37043 Red Cloud Court', 'qQ1_)/z{~EI5vGF', '1984/03/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH446901', 'Monroe Nicholls', 'F', '1949/10/11', '0671002841741', '1989/03/29', 'Russia', '0713773962', 'mnicholls7s@dell.com', '6107 Columbus Plaza', 'yD9$#''qfIsG3', '1990/07/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH801768', 'Arabela Etoile', 'F', '1965/03/24', '0358730449664', '1988/11/01', 'Ukraine', '0596765197', 'aetoile7t@spotify.com', '817 Maple Circle', 'nR0~1b_4$Xu~$~\%', '1973/12/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH473698', 'Denis Brundle', 'M', '1997/01/24', '0802921058445', '1982/02/26', 'Indonesia', '0241298355', 'dbrundle7u@noaa.gov', '394 Mccormick Pass', 'bS8_6z<x6hB$', '1999/08/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH814966', 'Maison Well', 'M', '1963/07/27', '0750489729425', '1992/11/29', 'Ukraine', '0647111516', 'mwell7v@xing.com', '46760 Sugar Avenue', 'tP2,1,\>9DOnc', '2018/11/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH951882', 'Ursuline Ewen', 'F', '1978/09/28', '0329886045799', '2008/01/06', 'Brazil', '0879505059', 'uewen7w@mapquest.com', '79479 Burrows Crossing', 'yI1?$1J4', '1969/09/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH235219', 'Ira Andreia', 'M', '1966/09/01', '0255433690146', '1968/05/12', 'South Africa', '0124712237', 'iandreia7x@furl.net', '678 Reinke Drive', 'hE8+I}EhQ', '1997/07/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH771399', 'Max Coite', 'F', '1995/07/17', '0022314891087', '1963/05/25', 'China', '0964856352', 'mcoite7y@prlog.org', '3 Cardinal Crossing', 'eH2\#~fiO*VY7', '2023/01/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH863030', 'Ariella Kedie', 'M', '1955/04/11', '0053941117097', '2008/09/15', 'Philippines', '0418309974', 'akedie7z@facebook.com', '529 Waubesa Avenue', 'eI4)YIl0', '2002/10/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH754040', 'Diane Cristoforo', 'F', '1959/07/28', '0012748684230', '2022/08/15', 'Palestinian Territory', '0797196800', 'dcristoforo80@forbes.com', '849 Autumn Leaf Parkway', 'rV4.2F_ns1LqST', '1970/02/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH928059', 'Jeanne Traite', 'M', '1996/08/21', '0124985197424', '1964/12/15', 'Philippines', '0774170416', 'jtraite81@census.gov', '005 Myrtle Plaza', 'kL3$730bS', '1970/08/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH216038', 'Stephana Turbitt', 'F', '1964/10/29', '0996433054847', '1990/06/05', 'Russia', '0373785910', 'sturbitt82@intel.com', '73 Longview Center', 'qA8}xXjc}h.DP}Y"', '1979/06/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH935820', 'Darius Mulliner', 'M', '1956/11/08', '0170040891714', '1982/12/06', 'Egypt', '0179201194', 'dmulliner83@cyberchimps.com', '5 Mitchell Circle', 'yC5|tW$x2{Mg\s`', '1985/01/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH900537', 'Killie Jaszczak', 'F', '1985/05/19', '0471380548937', '1993/12/25', 'Philippines', '0088860502', 'kjaszczak84@vistaprint.com', '63 Onsgard Alley', 'zX7_''Q}l*e', '1989/10/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH761758', 'Arly Bartlam', 'M', '1956/12/29', '0689809030740', '1965/08/16', 'Russia', '0713332978', 'abartlam85@joomla.org', '8 Hintze Street', 'oO3''6z/=', '2014/11/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH094387', 'Cthrine Moylan', 'M', '1991/03/02', '0220902950853', '1993/04/28', 'China', '0491809873', 'cmoylan86@china.com.cn', '03 Melvin Pass', 'pA5.2pDYpe*HE}HH', '2006/06/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH842523', 'Farrah Deaton', 'M', '1974/05/22', '0634556373724', '2007/06/11', 'Guatemala', '0510117905', 'fdeaton87@economist.com', '195 Carey Point', 'vQ3(2x7<', '1990/04/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH086370', 'Allissa Lorkin', 'F', '1969/08/13', '0100191467047', '2003/12/07', 'Indonesia', '0993389932', 'alorkin88@nyu.edu', '014 Holmberg Lane', 'pB3/w&f2!%O', '2005/07/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH891601', 'Moises Sabie', 'M', '1991/03/14', '0393506960114', '1963/02/20', 'Indonesia', '0483376747', 'msabie89@blog.com', '47638 Roth Road', 'xR8_R%l,2hp/O9', '1976/09/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH147192', 'Larisa Lehrle', 'F', '1980/07/02', '0894390032769', '1986/05/19', 'Russia', '0115743373', 'llehrle8a@i2i.jp', '08243 Rowland Hill', 'bA7!3{Ig?.}k', '2011/04/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH641772', 'Frederick Grix', 'F', '1972/08/14', '0926055373617', '2012/10/27', 'Mexico', '0612432460', 'fgrix8b@ted.com', '140 Hoard Road', 'lS3#6qe*NX', '1980/09/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH205267', 'Mohandas Braunle', 'M', '1967/04/10', '0139363566345', '2010/10/13', 'China', '0357936624', 'mbraunle8c@forbes.com', '9 Kipling Point', 'nI8$VOx=eN/QUCcK', '1992/07/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH936694', 'Trish Coules', 'F', '1979/07/11', '0288532947461', '1997/08/20', 'Nicaragua', '0636623724', 'tcoules8d@theguardian.com', '481 Manley Circle', 'dQ3!H3d.', '2016/03/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH141805', 'Marj Kilmaster', 'F', '1974/06/30', '0486336993886', '1989/04/06', 'Taiwan', '0424622340', 'mkilmaster8e@behance.net', '956 Superior Park', 'dW9''qbz,1B', '2005/12/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH116105', 'Horton Ferriday', 'F', '1965/10/04', '0078019598330', '1969/01/28', 'Spain', '0942211119', 'hferriday8f@blogger.com', '03466 Colorado Lane', 'rJ7.p9m&!oj', '2023/01/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH490206', 'Brockie Huncoot', 'M', '1977/01/10', '0468917795262', '1972/01/29', 'Bolivia', '0581010184', 'bhuncoot8g@webnode.com', '67228 Nancy Alley', 'iG7&ya7jv', '2020/01/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH027997', 'Carree Couldwell', 'F', '1963/12/01', '0169008138328', '2010/11/12', 'Belarus', '0850710944', 'ccouldwell8h@wordpress.org', '8 Annamark Pass', 'kI8<oA'')xhnHF+Ov', '2022/10/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH402958', 'Jenn Chastagnier', 'F', '1983/10/06', '0306859591971', '1966/07/21', 'South Africa', '0697903391', 'jchastagnier8i@dropbox.com', '334 Oneill Road', 'cK0*`*hd){', '2016/06/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH988988', 'Bobbie Slowly', 'F', '1978/12/14', '0622121037365', '2013/05/07', 'China', '0063619708', 'bslowly8j@xrea.com', '093 Fairview Lane', 'mX0_<B/z5wOn#4Z', '2018/03/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH574776', 'Bellanca Chanter', 'F', '1961/06/23', '0345444697882', '2009/05/08', 'Canada', '0207226584', 'bchanter8k@google.com.hk', '3884 Schurz Park', 'hU9=2BF=+&2', '1983/09/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH478576', 'Anetta Darinton', 'F', '1953/06/06', '0030967865509', '1972/05/26', 'Russia', '0126256068', 'adarinton8l@nifty.com', '39400 Morningstar Lane', 'jM7+quXh"0''(\', '2022/09/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH694938', 'Harbert Olle', 'M', '1965/02/17', '0809610544106', '1992/10/07', 'China', '0015233238', 'holle8m@foxnews.com', '21 Village Green Alley', 'pP6)9vYr!?', '2013/02/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH278608', 'Gaspar Lurriman', 'M', '1983/10/18', '0914969808125', '1963/10/09', 'Vietnam', '0246980456', 'glurriman8n@usa.gov', '57019 Milwaukee Terrace', 'oH4/M<&NT4vmi', '1995/10/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH677059', 'Mikaela Connikie', 'M', '1960/07/20', '0133565668460', '2010/08/27', 'Tajikistan', '0965188325', 'mconnikie8o@umich.edu', '2 Vernon Hill', 'fE4?K`Ph~tqwfW', '1966/12/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545881', 'Fianna Freeborne', 'F', '1950/12/01', '0576824890500', '1965/08/07', 'Indonesia', '0846145355', 'ffreeborne8p@taobao.com', '0654 Graedel Parkway', 'hV3%4M{c,l@3', '2016/03/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH391834', 'Tanitansy Godsafe', 'M', '1947/02/27', '0672715766589', '1988/04/23', 'Portugal', '0085059527', 'tgodsafe8q@ning.com', '77599 Golf Lane', 'yZ6.kF<nuA>,C*/', '1982/03/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH920085', 'Nevile Williscroft', 'F', '1988/02/28', '0519141090527', '2020/02/23', 'China', '0606036806', 'nwilliscroft8r@rambler.ru', '7 Harper Way', 'eP0`P7?c9>0', '2003/12/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH683530', 'Johny Bugdell', 'M', '1950/09/08', '0818726031766', '1995/06/12', 'Indonesia', '0728833694', 'jbugdell8s@csmonitor.com', '1 Fisk Circle', 'kC7<=|sHAj$?I', '2020/07/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH461638', 'Filmer Pirelli', 'F', '1997/02/18', '0110145691376', '1971/10/19', 'Ukraine', '0245762502', 'fpirelli8t@constantcontact.com', '3154 Mockingbird Way', 'pF3?._~olzm', '1976/04/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH820199', 'Paulina Redman', 'M', '1965/07/13', '0312564534919', '1982/03/21', 'Czech Republic', '0422788967', 'predman8u@oracle.com', '2012 Rutledge Parkway', 'pZ2>`cHB)zD', '1963/08/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH796519', 'Donica Gwioneth', 'M', '1964/07/19', '0114835448742', '1990/07/30', 'Democratic Republic of the Congo', '0994654030', 'dgwioneth8v@latimes.com', '1559 Hallows Drive', 'vN6@R&?o!01I(', '1968/02/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH171568', 'Abie Dionsetto', 'F', '1946/01/20', '0713412206117', '1980/06/12', 'Poland', '0495701578', 'adionsetto8w@cbc.ca', '1334 Merry Alley', 'dS3,Zt)$g.M', '1996/06/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH588852', 'Ginger Cleave', 'M', '1970/01/16', '0726007197602', '1969/12/03', 'Tunisia', '0860086714', 'gcleave8x@plala.or.jp', '81499 Arizona Avenue', 'wT4$Q&_3(<Z', '2014/06/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH581468', 'Laurence Delle', 'M', '1976/03/25', '0126983575952', '1971/12/28', 'Norway', '0307393130', 'ldelle8y@behance.net', '7944 Meadow Valley Junction', 'bZ5~)17M=R"#XEcr', '1972/06/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH132801', 'Ezequiel Larderot', 'M', '1991/10/30', '0515894053122', '1999/04/13', 'Brazil', '0325045443', 'elarderot8z@china.com.cn', '3 Lunder Point', 'tT3_%y(_/.(Us"aE', '1966/07/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH872145', 'Joly Laskey', 'M', '1969/10/14', '0226563977596', '2010/11/18', 'Norway', '0168626995', 'jlaskey90@wikia.com', '7 Kingsford Lane', 'zG3?uVe5H|*!Q~', '1980/11/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH376081', 'Biddy Quiddinton', 'M', '1975/01/15', '0076255354850', '2020/05/25', 'Indonesia', '0338771441', 'bquiddinton91@yale.edu', '81 Aberg Parkway', 'kT8{U6W(m9!o&', '1988/11/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH158297', 'Inge Redit', 'M', '1951/05/03', '0775035888512', '1978/05/22', 'Russia', '0784640013', 'iredit92@blinklist.com', '3 Raven Road', 'jV2|7M`n', '2023/02/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH400597', 'Carl Mallon', 'M', '1998/08/05', '0084763412956', '1994/02/01', 'New Caledonia', '0910913349', 'cmallon93@newyorker.com', '2 Rusk Center', 'wN6|%}>YA_pRg%EQ', '2001/06/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH952123', 'Zeb Burman', 'M', '1983/09/10', '0588102633779', '1978/10/13', 'Albania', '0306830554', 'zburman94@sitemeter.com', '30 Spohn Plaza', 'jB9%=+pYI{ah0c<', '2012/02/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH096988', 'Gabriella Stanes', 'F', '1975/06/05', '0879651495432', '2007/10/21', 'Syria', '0169537810', 'gstanes95@youtu.be', '0731 Eliot Hill', 'mT8</ue>.SQ', '1992/04/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH121401', 'Patricio Wilmut', 'F', '1947/06/30', '0836003515912', '2005/06/01', 'Poland', '0916014553', 'pwilmut96@list-manage.com', '2 Towne Way', 'iC5!nyN,ve', '2023/04/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH301524', 'Agatha Scotsbrook', 'F', '2004/07/14', '0334492979511', '2009/10/08', 'Portugal', '0189685911', 'ascotsbrook97@scribd.com', '86 Cascade Hill', 'rT4"Rm\a(z,cpI', '2007/10/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH057137', 'Lilian Smees', 'M', '1952/02/23', '0375868780212', '1973/11/18', 'Indonesia', '0781030170', 'lsmees98@tinypic.com', '2229 Village Green Center', 'nI7=WJcKS?sO5f)', '2024/03/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH713210', 'Brody Brunt', 'M', '1962/09/14', '0104360306441', '1974/09/11', 'Luxembourg', '0203221771', 'bbrunt99@ucsd.edu', '3218 Truax Point', 'bQ3}RWHOij/A', '1982/04/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH056635', 'Thorstein Hartly', 'M', '1992/06/16', '0743687337020', '1990/02/03', 'Brazil', '0572842671', 'thartly9a@foxnews.com', '0 Nevada Place', 'oU2,>D\i', '1984/07/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH741406', 'Waneta Warr', 'M', '1949/07/06', '0934305209339', '2001/02/01', 'Greece', '0389974413', 'wwarr9b@examiner.com', '47 Lunder Plaza', 'vF2/M)o`"', '1997/04/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH320177', 'Linell Miettinen', 'M', '1998/10/29', '0098719889053', '2016/08/19', 'Syria', '0190037152', 'lmiettinen9c@artisteer.com', '4 Arrowood Road', 'wD0>Z/")i@}*Am}', '2010/01/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH614014', 'Edin Park', 'F', '1998/10/06', '0195865622925', '1970/03/28', 'Argentina', '0765218066', 'epark9d@elegantthemes.com', '00 Ronald Regan Crossing', 'lM5)Cdco,X)?_2yV', '2001/06/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH502528', 'Bendite Conaghan', 'F', '2000/06/03', '0736163185927', '2017/01/01', 'Netherlands', '0218028553', 'bconaghan9e@bloglovin.com', '1120 Fair Oaks Lane', 'aJ0|irzu', '1984/09/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH800404', 'Maxine Brickstock', 'M', '1994/09/24', '0379267573450', '1978/10/06', 'United Kingdom', '0039726111', 'mbrickstock9f@europa.eu', '49 Cambridge Court', 'lS8!7MK(O', '2017/05/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH922933', 'Anatola Ettridge', 'F', '1956/03/26', '0186788095251', '1965/07/23', 'Czech Republic', '0261838915', 'aettridge9g@dyndns.org', '88641 Nova Center', 'jQ1?},RK', '2010/10/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH011144', 'Cchaddie Mathes', 'F', '1990/03/09', '0824401136851', '1989/01/25', 'Indonesia', '0963148778', 'cmathes9h@deliciousdays.com', '924 Amoth Junction', 'tP3)ciiNM}Jafq', '2002/09/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH773285', 'Anthony Klimsch', 'M', '1988/03/29', '0473447519453', '2005/03/22', 'Honduras', '0984429332', 'aklimsch9i@sohu.com', '7 Browning Drive', 'zH5?K0''6.hv{', '2009/05/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH321131', 'Ricard Hansod', 'F', '2001/05/07', '0118462894778', '1998/11/22', 'China', '0467109039', 'rhansod9j@google.pl', '5 Springs Road', 'vP3!c{?sB_#)l', '1988/11/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH025130', 'Guglielmo Phillipp', 'F', '1979/03/06', '0614242779910', '1994/02/12', 'Czech Republic', '0216145395', 'gphillipp9k@abc.net.au', '98 Luster Hill', 'fK6$8>oxbWZebZ"', '2018/12/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH678274', 'Ronica Garred', 'F', '1992/05/15', '0960121544569', '1978/04/08', 'Philippines', '0977601059', 'rgarred9l@privacy.gov.au', '9691 Oakridge Terrace', 'xI3{f}`Z~NO', '1966/08/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH664884', 'Benedetto Saltman', 'M', '1961/03/24', '0407917929266', '2019/10/26', 'Poland', '0109485070', 'bsaltman9m@trellian.com', '30280 Katie Crossing', 'nL6.S3a4', '1989/08/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH658936', 'Floyd Stutard', 'M', '1955/07/12', '0001081666370', '2013/06/08', 'Poland', '0034650388', 'fstutard9n@springer.com', '18 Holmberg Center', 'aP2&/y6Yb', '1990/10/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH052434', 'Nessa Hards', 'M', '1980/04/21', '0116313066053', '1997/08/14', 'Poland', '0712884410', 'nhards9o@vk.com', '7 Vera Place', 'dE3?\ccVQ`k', '2018/03/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH830363', 'Rodi Sacchetti', 'M', '1974/06/04', '0263977073370', '2019/01/09', 'Brazil', '0109781694', 'rsacchetti9p@examiner.com', '5 Valley Edge Crossing', 'eP7%w|2b.o{', '2023/07/31', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH878182', 'Karlie Collumbine', 'F', '1978/09/09', '0212067255981', '1966/11/24', 'China', '0392561067', 'kcollumbine9q@msu.edu', '2769 Elgar Alley', 'cX8/g<I,j', '2011/06/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH378830', 'Andres Moland', 'M', '1955/12/03', '0598959531880', '1989/11/29', 'Brazil', '0188425104', 'amoland9r@list-manage.com', '91731 Comanche Crossing', 'zO7+Y7(=RKU*I', '1981/05/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH568004', 'Bran Carnihan', 'F', '1977/03/05', '0298431581714', '1972/08/31', 'Colombia', '0946915855', 'bcarnihan9s@google.co.jp', '8 Michigan Street', 'sH5,Enk"|jV', '1984/05/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH976204', 'Erin O''Boyle', 'F', '2003/04/09', '0874734589131', '1989/01/12', 'Peru', '0706823267', 'eoboyle9t@ucoz.com', '3 Roxbury Junction', 'hM0@t||b<5IPG', '1980/02/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH545916', 'Cherry Gorden', 'F', '1960/10/16', '0672973963489', '2017/08/03', 'Indonesia', '0847667682', 'cgorden9u@squarespace.com', '9 Fremont Crossing', 'lV9)>Mv?F,)/', '2020/07/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH987019', 'Alleyn Massimi', 'F', '1953/03/27', '0756206498260', '2014/08/14', 'China', '0570251570', 'amassimi9v@hexun.com', '11961 Michigan Point', 'tU1_+w7CZ<M?Rv', '1978/06/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH723964', 'Giff Awcoate', 'M', '1994/05/30', '0802942058913', '2021/10/19', 'Albania', '0745806939', 'gawcoate9w@storify.com', '26828 Carberry Road', 'fO4*$raW', '1997/08/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH695437', 'Melodie Askham', 'M', '1953/11/20', '0617615309316', '1966/10/09', 'Bosnia and Herzegovina', '0722337464', 'maskham9x@prlog.org', '760 Eastlawn Parkway', 'qV0"GP8YR', '1988/05/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH947121', 'Elga Gayler', 'F', '1955/04/17', '0111340817879', '2017/11/15', 'Peru', '0613837231', 'egayler9y@census.gov', '47945 Waywood Point', 'qN6#8rmQp', '1976/08/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH919695', 'Hermie Balcon', 'M', '2002/10/13', '0447122195834', '2009/05/12', 'Vietnam', '0646016445', 'hbalcon9z@chron.com', '75882 Grover Park', 'kL6$dGd5XZ<7h', '1984/05/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH473189', 'Imelda Pauling', 'M', '1984/03/22', '0809940062850', '2013/07/18', 'Russia', '0465182226', 'ipaulinga0@unc.edu', '71 Calypso Crossing', 'pK4_C8HHFb\8@0~Q', '2009/02/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH226216', 'Gabey Revening', 'M', '1999/05/27', '0687941050400', '1975/09/12', 'Japan', '0350891058', 'greveninga1@examiner.com', '8883 Clemons Hill', 'zJ1!VLlL_', '1993/06/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH958880', 'Emmie Fishbourne', 'M', '1950/09/21', '0502049640910', '1995/04/04', 'China', '0109166216', 'efishbournea2@liveinternet.ru', '315 Little Fleur Hill', 'tQ6\|XAPQP49A', '1980/11/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH428245', 'Dona Pitcaithley', 'M', '1960/07/18', '0731309584863', '2007/10/13', 'United States', '0826421932', 'dpitcaithleya3@guardian.co.uk', '94864 Lawn Point', 'mG1_vBSY*{hPUd_@', '1978/05/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH358537', 'Lotti Swanne', 'M', '2001/12/18', '0530888709804', '2010/09/13', 'Serbia', '0551674800', 'lswannea4@newyorker.com', '1820 Linden Park', 'oS5.zm\O`gALs', '2014/12/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH076629', 'Marthena De Vere', 'M', '1977/01/18', '0604224306641', '1964/06/11', 'Mali', '0247837910', 'mdea5@clickbank.net', '432 International Terrace', 'pT8!pnnyAH', '2001/12/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH544891', 'Sargent Bewick', 'F', '1978/10/03', '0755215925572', '2007/05/22', 'Brazil', '0302202006', 'sbewicka6@constantcontact.com', '038 Coolidge Drive', 'uL6$/wp''FJ>F2p8n', '2024/04/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH083305', 'Roz Whitehurst', 'F', '1998/08/13', '0384205674805', '1967/05/21', 'Tunisia', '0901153616', 'rwhitehursta7@admin.ch', '0 Coolidge Plaza', 'zH9<r%+kJ', '1966/09/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH569847', 'Janith Gabel', 'M', '2002/08/24', '0357480068092', '2014/12/15', 'Yemen', '0606291586', 'jgabela8@google.com.br', '41 Granby Circle', 'xC1<QLCp/Kz#H<', '1995/08/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH419510', 'Roxy Marshalleck', 'F', '1958/01/11', '0159063696780', '2000/01/31', 'Vietnam', '0944655524', 'rmarshallecka9@ucla.edu', '1 Barby Park', 'zU6?ZyiGPw', '1981/07/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH112531', 'Maximilianus Benitez', 'F', '1974/03/16', '0592243993955', '2001/01/19', 'Jordan', '0275630650', 'mbenitezaa@google.com.au', '22556 Boyd Trail', 'dD4\LRn|gcENH!%2', '1963/12/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH684144', 'Eugenius Silverson', 'M', '1999/04/09', '0133384678574', '1996/06/04', 'Mauritania', '0802365105', 'esilversonab@baidu.com', '53 Roth Plaza', 'nF2"v<#N{', '2012/06/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH169494', 'Lewie Desseine', 'F', '1954/06/15', '0538312364876', '2019/03/11', 'Philippines', '0872043290', 'ldesseineac@gizmodo.com', '9777 Raven Plaza', 'pD2?fu(K/f12', '1982/12/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH052955', 'Johnath Schinetti', 'M', '1981/04/23', '0418803173109', '1999/09/24', 'Japan', '0915218810', 'jschinettiad@qq.com', '92 Nelson Center', 'jE8>_OH1coZ', '1972/04/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH829383', 'Ruby Farnsworth', 'F', '2005/01/27', '0261860961153', '2004/12/12', 'Indonesia', '0101957809', 'rfarnsworthae@cafepress.com', '0043 Bluestem Park', 'pU0&.Kpu}qIKX"J4', '1974/06/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH375794', 'Forrest Aucott', 'M', '1961/05/21', '0807701802998', '1986/01/18', 'Mali', '0982335244', 'faucottaf@infoseek.co.jp', '689 Debs Place', 'jN7#r=Momd', '2013/12/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH909409', 'Jeffrey Creevy', 'M', '1987/03/29', '0055180280282', '2008/04/22', 'Croatia', '0037465535', 'jcreevyag@senate.gov', '0748 Bluestem Street', 'xS4*25\(u~', '2014/10/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH083638', 'Demetris Galbreth', 'M', '1985/04/06', '0872418779203', '1998/08/22', 'Colombia', '0816815777', 'dgalbrethah@aol.com', '3532 Kingsford Hill', 'kT0`GG5D', '2006/11/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH216186', 'Trev Penner', 'M', '1947/02/26', '0692493183868', '2015/06/28', 'Russia', '0862115960', 'tpennerai@freewebs.com', '0 Ridgeway Point', 'xQ1"YN)opOz', '1986/01/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH013100', 'Marchall Treffrey', 'F', '1963/09/27', '0717123395466', '2023/11/07', 'Syria', '0517591377', 'mtreffreyaj@alibaba.com', '2 Lillian Hill', 'dX1#)+h4~%)n+y', '1975/01/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH601439', 'Emmalee Wixon', 'F', '1958/10/31', '0762048263930', '1974/05/15', 'South Africa', '0565949247', 'ewixonak@themeforest.net', '5843 Gina Crossing', 'mC3(72pf5lZ_@,Fx', '2007/12/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH070493', 'Rowe Gehring', 'M', '1989/12/21', '0744677717089', '1992/12/09', 'Madagascar', '0421134252', 'rgehringal@berkeley.edu', '4 Gateway Lane', 'aW5'')#rAsFz>%', '1965/04/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH206991', 'Melitta Haime', 'F', '1977/08/05', '0291480600110', '1980/04/23', 'China', '0726125271', 'mhaimeam@people.com.cn', '0 Pierstorff Plaza', 'wG6(\yr''FSlP', '1979/02/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH635995', 'Quintin MacCostye', 'F', '1980/11/10', '0953567006572', '1965/04/02', 'Russia', '0922217545', 'qmaccostyean@wikimedia.org', '38656 Pearson Center', 'dN8$wIU%N7', '2018/01/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH904366', 'Idaline Deverall', 'F', '1989/12/25', '0783585587426', '2010/09/28', 'Russia', '0756069376', 'ideverallao@va.gov', '9 Amoth Terrace', 'uP6"Li4(''l', '1979/12/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH435448', 'Naoma Butteris', 'F', '1980/04/08', '0902809553901', '1970/06/09', 'Bolivia', '0934081504', 'nbutterisap@java.com', '74238 Meadow Vale Junction', 'zZ3?isAh2''JfO', '2008/10/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH384345', 'Bourke Pantling', 'F', '1969/09/17', '0432360117096', '1993/10/11', 'Indonesia', '0957752126', 'bpantlingaq@163.com', '5 Del Sol Plaza', 'vV0{i}7H2+`X', '1967/10/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH714295', 'Elysha Robertis', 'M', '1953/01/18', '0408044477104', '1971/01/04', 'Bolivia', '0655279367', 'erobertisar@google.de', '2 Novick Lane', 'sF6("6bz', '1987/04/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH480965', 'Beatriz Jurczak', 'F', '1998/07/29', '0343351736145', '1970/11/24', 'Canada', '0719779718', 'bjurczakas@drupal.org', '95760 5th Point', 'gT9`kM3T*Er(nom', '1991/01/06', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH986650', 'Lina Lindemann', 'F', '1966/10/30', '0141424864333', '2004/03/23', 'Indonesia', '0191819274', 'llindemannat@miitbeian.gov.cn', '6 Miller Center', 'tO1{i,kqVC5cK', '1999/09/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH313588', 'Desirae Alldre', 'M', '1946/01/17', '0442865672952', '1969/06/30', 'Armenia', '0885789894', 'dalldreau@mediafire.com', '9122 Helena Court', 'bH4"plte28y', '2002/12/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374574', 'Ardenia Ralton', 'F', '1991/05/12', '0730156939233', '1966/07/08', 'Sweden', '0621311261', 'araltonav@linkedin.com', '39207 Pankratz Drive', 'kX4|aQ''R''', '2003/01/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH766023', 'Culver Bramall', 'F', '1988/08/11', '0181303746566', '2013/04/14', 'Mexico', '0964284098', 'cbramallaw@home.pl', '935 Cordelia Park', 'rF0{e6=c2R', '2000/02/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH080952', 'Jesse Sterke', 'F', '1985/11/03', '0619406301967', '2014/11/10', 'Colombia', '0034175585', 'jsterkeax@phpbb.com', '4 Holmberg Avenue', 'eB7~pi\AAciNaR6', '1986/08/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH017376', 'Pattin Blenkensop', 'F', '1996/10/25', '0417622549828', '1990/06/04', 'Brazil', '0378621992', 'pblenkensopay@dailymail.co.uk', '07265 Brickson Park Lane', 'rP3{=3~2KlmJc?H3', '1978/10/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH615996', 'Christal Rodliff', 'F', '1991/05/25', '0777299634823', '1985/06/04', 'Belarus', '0754378684', 'crodliffaz@ucla.edu', '1546 Farwell Circle', 'hK7#DIt''9', '1983/09/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH170428', 'Gearard Lavell', 'F', '1971/08/28', '0042064622395', '2010/02/28', 'Philippines', '0242174257', 'glavellb0@symantec.com', '33077 Swallow Circle', 'tV7@~G/E#,yB9D8', '1966/02/20', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH154664', 'Aldwin Smallcomb', 'F', '2004/11/11', '0484127094021', '2013/01/05', 'China', '0567110961', 'asmallcombb1@spotify.com', '50 Pond Lane', 'vN3=DjLQ', '1989/07/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH017103', 'Gael Gjerde', 'F', '1948/08/20', '0062793209068', '1995/08/21', 'Cyprus', '0229851282', 'ggjerdeb2@bbc.co.uk', '26 Canary Pass', 'yG1`sM<F&0', '1978/01/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH651808', 'Elwin Attwell', 'M', '1971/07/17', '0629702754784', '1979/12/15', 'Sweden', '0081213465', 'eattwellb3@example.com', '795 Arkansas Alley', 'xR9\''/L{H0', '1997/02/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH741003', 'Terri Rasher', 'M', '1986/05/30', '0791715694061', '2018/11/16', 'Indonesia', '0597222563', 'trasherb4@examiner.com', '61 Norway Maple Street', 'zA0?JgbxMH=*', '2004/02/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH868676', 'Kati Clout', 'M', '1949/01/21', '0649193121086', '2015/02/10', 'Mexico', '0828057276', 'kcloutb5@phpbb.com', '942 Union Lane', 'rR1"@r6SeMpd59', '1963/11/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH086511', 'Jarrid Clulow', 'M', '1992/02/26', '0489775037619', '1982/01/16', 'Indonesia', '0644480316', 'jclulowb6@usa.gov', '75273 Almo Drive', 'wB7_+w*~21W', '1982/05/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH628354', 'Gisele Anthes', 'M', '1993/02/23', '0411772619004', '1991/02/16', 'Indonesia', '0730272231', 'ganthesb7@sphinn.com', '53161 Warrior Point', 'kW5>nH>gYEqy', '2001/04/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH682141', 'Gradeigh Newlands', 'M', '1964/02/03', '0986290648071', '2000/10/15', 'Nigeria', '0050335202', 'gnewlandsb8@tripadvisor.com', '20511 Commercial Place', 'rX2@7tCZWQ%x(3%S', '1977/10/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH119243', 'Kennith Message', 'F', '1947/12/07', '0790357071233', '2007/09/18', 'China', '0573452635', 'kmessageb9@4shared.com', '61 Arkansas Point', 'vX7@''sE<W.2i5\', '1985/05/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH098035', 'Nike Lambal', 'F', '1983/05/25', '0992004217815', '2021/11/06', 'Philippines', '0185456261', 'nlambalba@a8.net', '6 Declaration Circle', 'xB1)Dq`3w', '2007/07/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH811011', 'Caitrin Trousdell', 'F', '1991/03/29', '0594775603353', '1966/03/03', 'China', '0471191516', 'ctrousdellbb@gizmodo.com', '15 Forest Court', 'aF7''Y,F50+huPh.', '1970/06/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH563731', 'Mercie Greenstock', 'M', '1991/09/20', '0787572369357', '1970/07/01', 'Poland', '0551932431', 'mgreenstockbc@oaic.gov.au', '46065 Grayhawk Plaza', 'nL7=!*L.r|', '1993/07/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH089493', 'Sebastiano Fincke', 'F', '2001/05/08', '0196189706831', '1982/12/14', 'Sweden', '0621804772', 'sfinckebd@domainmarket.com', '43 Jay Crossing', 'mJ7,oc09%', '1973/01/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH535109', 'Freddi Sommerlin', 'M', '1972/12/03', '0839621425859', '2024/06/23', 'China', '0070546342', 'fsommerlinbe@ezinearticles.com', '5 Petterle Plaza', 'sZ2$X""UUUR', '2003/06/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH819668', 'Tania Slograve', 'M', '1968/06/25', '0402661593678', '1968/09/18', 'Ukraine', '0343252175', 'tslogravebf@ocn.ne.jp', '3 Milwaukee Hill', 'tX3=DfiE>1bh=', '2001/09/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH944491', 'Jeannine O'' Lone', 'F', '1946/06/04', '0374153637000', '1989/07/28', 'Colombia', '0762656546', 'jobg@youtube.com', '88 Old Gate Alley', 'qJ7*ghyE93L', '1972/05/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH158688', 'Binny Tiery', 'M', '1949/09/13', '0984332610565', '1980/09/30', 'Vietnam', '0473517401', 'btierybh@zimbio.com', '76 Fulton Center', 'qL2_M!Z8', '2010/04/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH740368', 'Cordelie Caddan', 'F', '1951/02/15', '0236863457518', '2010/03/25', 'Indonesia', '0728606767', 'ccaddanbi@topsy.com', '02 Golden Leaf Crossing', 'lX8|sRPE#=fa*N', '1969/09/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH301394', 'Karie Leverette', 'F', '1990/12/24', '0076534697703', '1993/02/19', 'Philippines', '0817991350', 'kleverettebj@google.de', '10741 Maple Way', 'vA9%0G*4(C', '1997/01/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH217106', 'Catherine Lindemann', 'M', '1978/01/14', '0050997241477', '1969/10/26', 'Greece', '0334701902', 'clindemannbk@berkeley.edu', '3 Springs Place', 'cW2"}Z)Ei!m_!z6', '2021/03/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH761950', 'De Mutlow', 'F', '1945/11/07', '0562091703416', '2011/06/10', 'Venezuela', '0295429519', 'dmutlowbl@adobe.com', '0 Acker Hill', 'hT2+{u\Qit4j5&', '1968/09/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH376951', 'Morie Kruschev', 'F', '1955/04/15', '0256613021105', '1997/07/17', 'Benin', '0154711471', 'mkruschevbm@thetimes.co.uk', '9 Veith Parkway', 'fB6(7yYBM', '2004/11/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH609611', 'Ferdinanda Embling', 'F', '1968/09/27', '0077576925375', '1972/01/01', 'China', '0313702585', 'femblingbn@ucsd.edu', '24962 Logan Park', 'nB0=hv"TF', '2017/03/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH004422', 'Jemie Prater', 'M', '1998/04/16', '0683055717214', '2020/05/29', 'Japan', '0177932075', 'jpraterbo@google.co.uk', '014 Crest Line Center', 'lP6&\<VdQM', '1980/10/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH313736', 'Konstance Shynn', 'M', '1990/02/12', '0683117980348', '1978/08/25', 'China', '0384910651', 'kshynnbp@purevolume.com', '59439 Thackeray Point', 'pO7(ytQ!)', '2013/06/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH215084', 'Niki Ankers', 'M', '1989/05/21', '0400997404251', '1979/01/25', 'Indonesia', '0013950684', 'nankersbq@un.org', '26148 Division Lane', 'hI2,j&Utpv', '1968/11/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH585269', 'Agnese Station', 'F', '1997/07/14', '0347688188939', '2010/11/07', 'Botswana', '0600094140', 'astationbr@sciencedaily.com', '62627 Mallory Court', 'uD1''g!Qq', '1990/12/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH734612', 'Joye Chaffey', 'M', '1995/06/23', '0530804707765', '1995/02/22', 'China', '0062799840', 'jchaffeybs@vkontakte.ru', '31 Calypso Crossing', 'gZ8}CQzt{Xz4', '1967/08/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH706729', 'Ben Ovendale', 'F', '1956/01/25', '0803785463005', '1986/08/27', 'Russia', '0331294254', 'bovendalebt@bloomberg.com', '8201 Porter Hill', 'uG0(9KosnPb', '1969/02/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH203563', 'Dexter Rekes', 'F', '1986/07/12', '0590629410719', '1992/01/19', 'Greece', '0870169500', 'drekesbu@adobe.com', '2036 Granby Circle', 'zM4)SfE7xy=A', '1993/07/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH366742', 'Waldo Bernhardi', 'F', '1975/06/18', '0316660636278', '2014/09/08', 'Philippines', '0287283765', 'wbernhardibv@fastcompany.com', '708 Drewry Hill', 'pR3&vT*#w', '2015/12/19', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH634297', 'Victoir Castiblanco', 'M', '1945/07/20', '0171646512790', '2012/03/13', 'Indonesia', '0079058801', 'vcastiblancobw@prweb.com', '140 Mayer Plaza', 'iA1?vX|?y\>''5ns', '2009/09/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH529157', 'Jock Gravie', 'M', '1969/08/11', '0424257551519', '2018/03/10', 'Albania', '0953228116', 'jgraviebx@ycombinator.com', '2 Loeprich Court', 'pT5/s08E3elEoS}', '1975/06/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH135574', 'Rutter Gerren', 'F', '1955/04/28', '0216720515148', '2008/08/24', 'Tanzania', '0890861018', 'rgerrenby@themeforest.net', '88876 Mosinee Plaza', 'xO5/`2x?>`#d{L', '1982/12/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH172746', 'Stanislaw Littlechild', 'F', '1951/12/08', '0133074172170', '2005/09/02', 'Sweden', '0209506779', 'slittlechildbz@msn.com', '331 Canary Plaza', 'qV0!ysxnRz(`0', '1964/12/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH870175', 'Josh Fitzsymonds', 'F', '1954/05/03', '0278863688240', '2020/05/23', 'China', '0690705001', 'jfitzsymondsc0@163.com', '97428 Forest Run Way', 'xY0*A65|u_', '1966/04/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH876167', 'Zorana Cronk', 'M', '1997/05/15', '0757265893837', '2007/05/12', 'Moldova', '0978164433', 'zcronkc1@census.gov', '72141 Bluejay Parkway', 'kY7?''lz!', '1967/12/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH006633', 'Rafaela Giacomelli', 'F', '1966/10/07', '0765687734381', '2014/04/22', 'China', '0500496075', 'rgiacomellic2@kickstarter.com', '810 Forest Dale Junction', 'cO0&8(RGOOQH8kh`', '1981/10/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH116058', 'Serene Guite', 'F', '1996/02/04', '0733034571170', '1963/09/25', 'Russia', '0217311956', 'sguitec3@weather.com', '41 Elgar Lane', 'oM9#<H,!uvOGlr0Y', '1999/12/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH320087', 'Fergus Benedito', 'F', '1974/12/22', '0994591687747', '1966/03/29', 'Ukraine', '0936713755', 'fbeneditoc4@qq.com', '2121 Bluejay Drive', 'qX2?R?a4W/', '2021/07/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH011844', 'Rebecka Drydale', 'M', '1993/10/23', '0516788163782', '1979/09/04', 'United States', '0324408295', 'rdrydalec5@youku.com', '3983 Summit Plaza', 'kA6!o0|dSx', '2011/08/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH083366', 'Angelina Scogin', 'M', '1960/04/13', '0636079747903', '1989/01/01', 'Russia', '0053563087', 'ascoginc6@parallels.com', '176 Susan Street', 'gX9,P>23iu4Z~U', '2005/12/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH541552', 'Egbert Kitchinham', 'F', '1965/12/07', '0912171536180', '1989/02/26', 'Mexico', '0515820004', 'ekitchinhamc7@comsenz.com', '67038 Cambridge Circle', 'xB6''4F$@_', '1976/11/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH697828', 'Joseph Rowler', 'M', '1993/11/23', '0133122374752', '2023/11/05', 'Indonesia', '0292315513', 'jrowlerc8@live.com', '3 Weeping Birch Crossing', 'jM6"ze~!+&.=$i$', '2000/07/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH249737', 'Marissa Huckle', 'F', '1971/09/18', '0703831527626', '2003/08/22', 'Brazil', '0393077493', 'mhucklec9@github.com', '87 3rd Road', 'iE2}E{4Nlh_', '1992/07/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH128339', 'Blondie Van Der Weedenburg', 'M', '1976/04/04', '0115209398763', '1997/09/27', 'Brazil', '0360884344', 'bvanca@craigslist.org', '0 Mosinee Parkway', 'qV1>`Kf5Y', '2008/12/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH537067', 'Cyndy Cully', 'M', '1950/09/17', '0203263252897', '1982/05/31', 'China', '0540247457', 'ccullycb@cocolog-nifty.com', '905 Shelley Hill', 'uJ4.C<dz+n5NfSU', '2022/05/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH204348', 'Ulberto Pearlman', 'F', '1963/11/29', '0032365182314', '1990/12/10', 'Ukraine', '0080516937', 'upearlmancc@ox.ac.uk', '6 Acker Road', 'sX8"_+k(Zb==CnD', '1990/06/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH151736', 'Jandy Klammt', 'M', '1987/08/05', '0837507357356', '1990/11/23', 'Brazil', '0874858506', 'jklammtcd@house.gov', '89 Hallows Avenue', 'zL5/N|pZ', '1997/06/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH302564', 'Kristi Fownes', 'M', '1952/05/16', '0470233365007', '1970/12/04', 'China', '0813275133', 'kfownesce@etsy.com', '1822 Victoria Hill', 'gC4|stzWx3M"Bq', '1967/11/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH506979', 'Tiffanie Buxam', 'F', '1990/09/15', '0739420840907', '1980/02/17', 'China', '0485672770', 'tbuxamcf@buzzfeed.com', '28085 Troy Lane', 'jW1(X_m7&@t5d', '1980/11/03', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH176414', 'Hewe Dryden', 'F', '1955/10/01', '0402487675294', '1972/02/12', 'United States', '0345165618', 'hdrydencg@comsenz.com', '8716 Mandrake Trail', 'dY8|kT7<(', '1964/06/24', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH143946', 'Kathlin Matelyunas', 'F', '1990/04/30', '0886937958795', '1965/05/24', 'Ukraine', '0433481914', 'kmatelyunasch@over-blog.com', '55 Anderson Junction', 'kR3_""0sD', '1974/07/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH790357', 'Larisa Osbaldeston', 'F', '1962/06/22', '0796806099905', '1979/01/28', 'Russia', '0016420547', 'losbaldestonci@wordpress.org', '47 Havey Lane', 'fC8?9~)F', '1967/12/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH319135', 'Carmen Virgin', 'F', '1961/07/21', '0926901798013', '2019/06/29', 'Portugal', '0376950322', 'cvirgincj@blogger.com', '65566 Bellgrove Court', 'uZ1,ai`&=nt,3_i|', '1974/03/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH234271', 'Gretel Crutchley', 'M', '1985/02/17', '0364084336699', '2007/10/31', 'Costa Rica', '0491076190', 'gcrutchleyck@nature.com', '03805 Mcbride Terrace', 'aJ9=cZ$lnIb~', '1981/09/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH339380', 'Maggee O''Neary', 'M', '1946/03/24', '0291592404525', '2015/07/23', 'Chad', '0131674793', 'monearycl@vk.com', '7 Rowland Parkway', 'oP3*/in25c4#pY', '1981/09/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH697088', 'Cesare Pochet', 'M', '1957/05/12', '0284268915885', '1985/01/24', 'Peru', '0942056149', 'cpochetcm@prlog.org', '59194 Talmadge Trail', 'vF4.#${GViF0', '1996/04/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH127997', 'Ingelbert Adamthwaite', 'M', '1973/05/16', '0794758231515', '2012/04/08', 'Serbia', '0681192897', 'iadamthwaitecn@icq.com', '46 Kensington Terrace', 'zA9\WKB/sC', '1979/01/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH277269', 'Juline Asser', 'M', '1968/08/01', '0616908895514', '1976/01/15', 'China', '0008329468', 'jasserco@wordpress.com', '45 Commercial Place', 'xF0"CcL?"', '1993/12/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH032071', 'Sheff Bickardike', 'M', '1969/10/23', '0816776543936', '2010/06/29', 'Indonesia', '0913245604', 'sbickardikecp@mashable.com', '18 Haas Way', 'wG4#,>L)pZ5XNf', '2020/08/30', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH124864', 'Teresita Setterington', 'M', '1958/08/06', '0107782659121', '1985/09/26', 'Peru', '0713898597', 'tsetteringtoncq@state.gov', '09298 Waywood Terrace', 'eU1$yL\7.>u', '1963/09/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH591464', 'Alastair Openshaw', 'F', '1966/03/02', '0847859354570', '2007/06/21', 'Pakistan', '0933326381', 'aopenshawcr@samsung.com', '225 Esker Point', 'vZ1''be{Ox', '2011/05/28', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH002015', 'Jacenta McCullouch', 'M', '1981/11/17', '0828467463889', '2010/07/29', 'Philippines', '0076041706', 'jmccullouchcs@upenn.edu', '29827 Hansons Pass', 'hO0"~4t!P)', '1983/12/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH870922', 'Darwin Palluschek', 'M', '1948/03/13', '0193492147249', '2006/01/03', 'China', '0416606161', 'dpalluschekct@amazon.co.jp', '07 Blackbird Court', 'pA3<fYZxJv%yEu{X', '2022/05/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH644301', 'Aurie Klauer', 'M', '2001/05/31', '0326089079274', '1992/04/01', 'Thailand', '0288918615', 'aklauercu@skype.com', '1 Farmco Drive', 'xM4"<rX1,u', '2016/02/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH941652', 'Fraser Bevan', 'M', '1970/08/20', '0575297304296', '2002/04/11', 'Poland', '0769206838', 'fbevancv@cocolog-nifty.com', '56 Straubel Park', 'sO2%xAMW?q', '1989/01/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH112948', 'Mariana Minall', 'F', '1977/07/30', '0345179613718', '1970/11/02', 'France', '0618718754', 'mminallcw@goodreads.com', '56 Toban Terrace', 'qA9~Sf6J)', '2014/05/18', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH291338', 'Ashby Ruffles', 'M', '1969/12/31', '0486677380705', '2011/01/06', 'Colombia', '0200032792', 'arufflescx@independent.co.uk', '42 7th Drive', 'jP0=MkB_', '2015/06/17', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH709442', 'Mirelle Grigs', 'M', '1957/04/05', '0466205930683', '1978/08/31', 'Philippines', '0728826512', 'mgrigscy@imgur.com', '6603 Gateway Parkway', 'tD5>liiTz', '1997/03/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH614593', 'Trixi Falconer-Taylor', 'M', '1971/04/19', '0968832246174', '1966/05/10', 'Russia', '0451226656', 'tfalconertaylorcz@businessweek.com', '151 Burrows Avenue', 'rV1/KH!K"l', '2020/02/12', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH348195', 'Fredelia Orpen', 'F', '2002/03/29', '0722695736120', '1970/11/08', 'Thailand', '0102688531', 'forpend0@buzzfeed.com', '80 Pearson Terrace', 'aR5}6.!6DDaL#', '1979/05/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH249985', 'Dunn Melliard', 'F', '1992/11/06', '0490009262609', '1973/04/16', 'French Polynesia', '0521824400', 'dmelliardd1@phpbb.com', '0824 Iowa Court', 'fA6($<m(', '1995/09/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH856822', 'Teresina Nye', 'M', '1997/12/03', '0931312090532', '1970/11/23', 'Colombia', '0673300775', 'tnyed2@t-online.de', '7 Anderson Way', 'hG3`sUcrp}''fp', '1964/11/27', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH832329', 'Fara Sheringham', 'F', '1948/12/10', '0538359681442', '1997/05/04', 'Philippines', '0960118208', 'fsheringhamd3@ibm.com', '87188 Russell Lane', 'zO3?ub=iSy<$4', '1971/08/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH249731', 'Chelsy Wintringham', 'M', '1986/08/11', '0207337967774', '1987/08/03', 'Haiti', '0718069539', 'cwintringhamd4@salon.com', '79287 Spaight Hill', 'gE1''\<%Et$}<=J@', '1963/03/25', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH890559', 'Mikol Harwin', 'F', '1980/11/07', '0126718114876', '1977/08/04', 'Sweden', '0124962898', 'mharwind5@mapy.cz', '91 Sunnyside Alley', 'dT8/t2CLI2k|t*', '1964/12/15', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH041169', 'Julian MacCostye', 'M', '1950/04/12', '0645962525807', '2020/07/15', 'Spain', '0070615559', 'jmaccostyed6@hud.gov', '24560 Troy Crossing', 'gQ2(D(*zDs7xcMN', '2020/06/13', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH464486', 'Raddie Buxey', 'M', '1953/04/15', '0591324278000', '1991/10/19', 'China', '0575999492', 'rbuxeyd7@51.la', '2 Sheridan Terrace', 'hU1+="ZSrqjc', '1963/07/04', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH739457', 'Gianina Bagshaw', 'M', '1993/08/31', '0051399188066', '1978/05/06', 'Philippines', '0356751840', 'gbagshawd8@berkeley.edu', '8 Basil Junction', 'qX8?(e)#Ip', '2009/04/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH179505', 'Leon Clewett', 'F', '1953/01/18', '0687658045234', '2003/05/08', 'Norway', '0501502133', 'lclewettd9@umn.edu', '197 Brown Road', 'yF8!n,{bj7SBIE', '2022/03/07', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH370303', 'Valery Babington', 'M', '1978/11/19', '0653664586987', '1983/06/16', 'Russia', '0746556936', 'vbabingtonda@toplist.cz', '95154 Onsgard Avenue', 'eP6%Becu{6<LzZ', '1983/04/09', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH494290', 'Rodi Guly', 'F', '1966/07/09', '0579668194791', '1997/02/09', 'Philippines', '0108857540', 'rgulydb@mozilla.org', '3 Hintze Street', 'tZ3#Tb)EJx.Z93>', '1973/04/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH437596', 'Archibald Wais', 'M', '1969/09/13', '0874674587274', '1992/02/11', 'Togo', '0219253050', 'awaisdc@foxnews.com', '22757 Messerschmidt Hill', 'iI5|d{.GYNF9Q', '1975/09/26', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH760944', 'Allie Valens-Smith', 'F', '1964/02/06', '0583231218661', '1972/09/02', 'Brazil', '0811680769', 'avalenssmithdd@usnews.com', '40 Fairfield Court', 'kL4=kaWe', '1985/03/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH145038', 'Kerwinn Bedbury', 'M', '1953/05/05', '0879378649700', '2011/11/05', 'Hungary', '0122409553', 'kbedburyde@google.co.uk', '6 Becker Parkway', 'bC0\_~d}?V#v<b~w', '2022/05/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH562909', 'Aaren Gillice', 'F', '1969/10/11', '0619690910231', '1979/04/27', 'China', '0172380260', 'agillicedf@who.int', '1 Briar Crest Circle', 'yV2|f+"Ih6', '2007/01/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH772577', 'Anatole Shemmin', 'M', '1952/06/06', '0953970940998', '1993/06/11', 'Myanmar', '0643009281', 'ashemmindg@freewebs.com', '7473 Superior Parkway', 'mZ9+t@9N(c,v$Y&', '1978/11/01', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH859460', 'Benjamen Stallwood', 'F', '1945/04/06', '0055474555924', '2024/04/08', 'Sweden', '0084777016', 'bstallwooddh@mapy.cz', '18633 Stang Circle', 'pZ7$fRN3b', '1972/09/29', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH949184', 'Isa Nobes', 'M', '1983/09/07', '0380192346951', '2014/09/09', 'Malaysia', '0016696264', 'inobesdi@nationalgeographic.com', '2 Veith Place', 'vM9/uRD`!(T.*#Wi', '1979/01/05', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH791759', 'Arvin Arndell', 'M', '1960/08/01', '0361426161927', '1969/01/22', 'Malaysia', '0629742802', 'aarndelldj@alibaba.com', '863 Bunker Hill Crossing', 'wM1%g7O=m*0l', '1963/12/21', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH133752', 'Ethelred Glasscott', 'M', '1967/05/18', '0751212168880', '2019/05/03', 'Croatia', '0613660397', 'eglasscottdk@icq.com', '57 Sachtjen Parkway', 'tS6<CP"|e4{=U.h#', '1965/12/14', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH957276', 'Hyatt Bilbery', 'M', '1952/10/11', '0959838546239', '2023/12/19', 'Portugal', '0304644037', 'hbilberydl@miibeian.gov.cn', '9 Fairfield Terrace', 'lY1{&xKP4rpV<KT', '2023/09/10', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH929292', 'Sonny Fried', 'M', '2000/08/25', '0416994728524', '2009/08/29', 'China', '0277501288', 'sfrieddm@symantec.com', '72495 Granby Park', 'vP0>>&~nzUG3a=$', '1977/11/11', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH374203', 'Garrik Woonton', 'F', '1959/05/08', '0843374468299', '1994/01/11', 'Russia', '0209477354', 'gwoontondn@miitbeian.gov.cn', '3783 Katie Place', 'wZ7}Y|FWgQN,"', '1996/10/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH237905', 'Chrissy Figurski', 'F', '1952/06/06', '0100088592516', '2017/06/19', 'Mexico', '0869259358', 'cfigurskido@yellowpages.com', '00593 Fisk Terrace', 'yZ7>qG$yl*SqhB', '2017/04/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH131158', 'Lexine Brignall', 'F', '1968/10/29', '0991847432892', '1977/04/29', 'China', '0846631376', 'lbrignalldp@skyrock.com', '987 Twin Pines Crossing', 'zV4?W+V''Q+b|u', '1981/08/08', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH233678', 'Magdaia Corhard', 'M', '2003/01/08', '0603407406065', '1981/10/21', 'Sweden', '0664674385', 'mcorharddq@apple.com', '64 Killdeer Hill', 'xO7\_K!m~~GR0|/', '1991/09/22', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH160641', 'Seana Tattoo', 'M', '1973/04/01', '0439769161236', '1981/01/25', 'Russia', '0818751154', 'stattoodr@springer.com', '0 Valley Edge Parkway', 'cM8,>h2bKX6K7y', '2022/10/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH274415', 'Elka Brobak', 'M', '1996/10/27', '0259913405178', '2022/08/02', 'Russia', '0689624425', 'ebrobakds@hc360.com', '51841 Maywood Avenue', 'xP8/0BsTX.yHL}>', '1992/09/16', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH084013', 'Bentlee D''Onisi', 'F', '1970/08/01', '0724076272555', '1984/02/23', 'Brazil', '0577522788', 'bdonisidt@china.com.cn', '36 Novick Hill', 'sW1/KgWItQ', '1977/09/02', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH668354', 'Bevin Peschke', 'M', '1991/09/15', '0228317092776', '2023/12/14', 'Ukraine', '0551346183', 'bpeschkedu@tuttocitta.it', '54651 Lyons Road', 'gT2+rr"ry#uL6XdM', '2005/06/23', 'KH');
insert into KHACHHANG (MAKH, TENKH, GIOITINH, NGAYSINH, CCCD, NGAYCAP, QUOCTICH, SODT, EMAIL, DIACHI, PASSWORD, NGAYTAOTK, MAVT) values ('KH149810', 'Michelle Gallear', 'F', '1989/10/17', '0504658724529', '2019/04/06', 'Philippines', '0588638665', 'mgalleardv@over-blog.com', '3 David Place', 'mV3\y`mQJe(O>', '1976/05/09', 'KH');

GO
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00000001', 'NV078538', 'KH496697', '2024/05/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00130557', 'NV078538', 'KH370303', '2023/06/14', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00140987', 'NV430597', 'KH004422', '2024/02/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00438831', 'NV376524', 'KH437409', '2024/06/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00614964', 'NV325416', 'KH870175', '2023/10/11', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('00921927', 'NV634749', 'KH941652', '2023/04/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01293073', 'NV281921', 'KH823023', '2023/08/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01357061', 'NV392010', 'KH554185', '2023/12/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01373041', 'NV477238', 'KH993336', '2024/07/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01616005', 'NV659671', 'KH454006', '2024/11/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('01977459', 'NV849197', 'KH344217', '2023/02/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('02704470', 'NV068235', 'KH496697', '2023/10/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('02998601', 'NV289904', 'KH350452', '2024/06/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('03227540', 'NV639320', 'KH160641', '2024/02/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('03909266', 'NV425018', 'KH044747', '2024/11/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04083258', 'NV308774', 'KH362680', '2023/04/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04356983', 'NV610092', 'KH290459', '2024/01/18', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04537853', 'NV240973', 'KH039286', '2023/02/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04581995', 'NV160815', 'KH772577', '2024/03/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04679087', 'NV775515', 'KH947121', '2024/01/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04828666', 'NV454412', 'KH147192', '2024/10/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('04858972', 'NV634749', 'KH483866', '2024/02/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05076247', 'NV540497', 'KH370303', '2023/02/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05146450', 'NV453523', 'KH297971', '2024/11/20', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05346638', 'NV098182', 'KH441817', '2024/05/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05396256', 'NV271794', 'KH919695', '2023/07/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05396895', 'NV787213', 'KH071341', '2023/03/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05469109', 'NV481500', 'KH293180', '2024/06/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05475100', 'NV391581', 'KH225380', '2024/07/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05502162', 'NV019077', 'KH355802', '2024/05/13', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05527832', 'NV444738', 'KH085398', '2023/09/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05596399', 'NV447108', 'KH419510', '2023/09/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('05949964', 'NV367893', 'KH469917', '2023/02/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06058572', 'NV732368', 'KH099791', '2023/03/25', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06062676', 'NV941879', 'KH437409', '2023/11/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06132492', 'NV012052', 'KH666660', '2024/08/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06225856', 'NV539311', 'KH582692', '2023/03/09', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06317278', 'NV822716', 'KH895693', '2024/02/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('06995735', 'NV945233', 'KH903096', '2023/02/26', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07129158', 'NV372709', 'KH707432', '2024/08/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07199807', 'NV925832', 'KH297971', '2023/03/31', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07542827', 'NV797940', 'KH013100', '2024/11/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('07854851', 'NV441589', 'KH828458', '2024/11/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08184228', 'NV012052', 'KH237905', '2023/02/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08391580', 'NV675961', 'KH987019', '2024/06/11', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08437144', 'NV444738', 'KH131158', '2024/03/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08617294', 'NV740277', 'KH945522', '2024/09/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08669987', 'NV303199', 'KH469917', '2023/11/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08846928', 'NV955988', 'KH791759', '2023/12/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('08986110', 'NV262355', 'KH237905', '2023/08/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('09685222', 'NV675961', 'KH057137', '2024/12/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('09860333', 'NV582109', 'KH658936', '2024/04/30', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10106971', 'NV440528', 'KH876167', '2023/10/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10174845', 'NV850038', 'KH339380', '2024/07/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10179483', 'NV079311', 'KH349897', '2023/08/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('10935131', 'NV098182', 'KH274415', '2023/10/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('11057658', 'NV189822', 'KH016282', '2024/11/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('11821755', 'NV481500', 'KH554185', '2023/04/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('12038966', 'NV047107', 'KH428245', '2024/06/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('12593587', 'NV303894', 'KH460998', '2023/11/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13227974', 'NV787213', 'KH929292', '2024/01/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13528822', 'NV325416', 'KH977771', '2024/03/04', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13740822', 'NV440528', 'KH358537', '2023/11/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('13933332', 'NV540497', 'KH714295', '2023/10/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14069840', 'NV308774', 'KH121401', '2023/08/21', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14258585', 'NV189822', 'KH056342', '2024/03/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14930507', 'NV158614', 'KH842523', '2023/07/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('14979073', 'NV019077', 'KH375073', '2023/06/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15076148', 'NV856226', 'KH666660', '2024/03/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15095037', 'NV619570', 'KH083638', '2024/07/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15139654', 'NV105604', 'KH008583', '2023/11/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15250752', 'NV850462', 'KH375073', '2023/03/31', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15308723', 'NV894914', 'KH365036', '2024/11/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15324566', 'NV413814', 'KH980984', '2023/03/24', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15422881', 'NV010574', 'KH271569', '2024/08/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15662805', 'NV453523', 'KH347468', '2023/11/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('15902113', 'NV073871', 'KH179505', '2023/09/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16103611', 'NV019077', 'KH176414', '2023/12/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16346188', 'NV735464', 'KH995610', '2024/09/04', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16456492', 'NV592137', 'KH772577', '2024/10/09', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16466095', 'NV770980', 'KH585669', '2023/12/01', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16531754', 'NV193026', 'KH741406', '2024/12/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16573625', 'NV738399', 'KH017103', '2023/03/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('16752375', 'NV850462', 'KH065196', '2024/07/04', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17056136', 'NV955885', 'KH492275', '2024/03/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17168656', 'NV240888', 'KH951882', '2023/08/11', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17178530', 'NV078937', 'KH823023', '2023/01/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17198837', 'NV193469', 'KH723964', '2024/12/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17387584', 'NV092108', 'KH234451', '2024/02/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17443686', 'NV193469', 'KH104498', '2023/04/11', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17506861', 'NV447108', 'KH558718', '2024/09/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17542571', 'NV059671', 'KH668354', '2023/06/20', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('17815063', 'NV240888', 'KH919695', '2024/07/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18045997', 'NV193026', 'KH079281', '2023/09/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18162373', 'NV343692', 'KH302564', '2023/02/15', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18169248', 'NV242498', 'KH820199', '2023/09/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18226382', 'NV160815', 'KH442934', '2023/03/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18282997', 'NV308774', 'KH716623', '2023/11/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18517549', 'NV078937', 'KH723964', '2023/03/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18580663', 'NV945233', 'KH132801', '2024/12/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('18719517', 'NV012052', 'KH052434', '2024/03/20', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19014083', 'NV277291', 'KH592532', '2024/11/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19249690', 'NV592137', 'KH641772', '2024/02/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19315538', 'NV790581', 'KH669019', '2023/06/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19453685', 'NV979641', 'KH773761', '2024/04/03', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19580154', 'NV539311', 'KH099791', '2023/07/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19594779', 'NV747397', 'KH535109', '2023/10/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('19761714', 'NV890913', 'KH339380', '2023/06/09', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20013655', 'NV945233', 'KH526686', '2023/11/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20049535', 'NV659802', 'KH988988', '2023/07/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20161572', 'NV201665', 'KH084753', '2024/09/21', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20391629', 'NV339957', 'KH945522', '2024/06/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20502716', 'NV240888', 'KH904366', '2023/03/28', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20765138', 'NV415824', 'KH919695', '2023/04/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('20852482', 'NV645678', 'KH169494', '2023/03/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21000317', 'NV047107', 'KH057137', '2023/10/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21047967', 'NV077006', 'KH460998', '2024/04/22', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21156781', 'NV044506', 'KH683530', '2023/05/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21163258', 'NV477238', 'KH690162', '2024/02/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21702680', 'NV888660', 'KH370775', '2024/05/23', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('21932175', 'NV481500', 'KH713210', '2023/07/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22170126', 'NV450177', 'KH545916', '2023/11/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22234337', 'NV955988', 'KH283594', '2023/11/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22376000', 'NV639320', 'KH462707', '2023/08/23', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22398445', 'NV234271', 'KH057855', '2024/09/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22535180', 'NV047107', 'KH667915', '2023/05/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('22610247', 'NV336685', 'KH227910', '2023/03/15', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23127223', 'NV376524', 'KH884843', '2024/09/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23187054', 'NV711456', 'KH141805', '2024/08/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23273614', 'NV711456', 'KH895693', '2024/02/04', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23558474', 'NV044506', 'KH714662', '2023/04/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('23760940', 'NV325416', 'KH641772', '2023/06/09', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24139505', 'NV440528', 'KH213357', '2023/08/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24243157', 'NV717819', 'KH599858', '2024/07/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24456745', 'NV289904', 'KH872145', '2023/08/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('24665394', 'NV550817', 'KH862046', '2023/09/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25142090', 'NV288830', 'KH008583', '2024/04/30', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25397161', 'NV487204', 'KH176414', '2024/09/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25535597', 'NV308774', 'KH554185', '2024/05/31', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('25788579', 'NV659671', 'KH895693', '2024/03/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26010133', 'NV955885', 'KH782287', '2023/01/25', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26677987', 'NV391581', 'KH227910', '2023/11/30', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26787626', 'NV634749', 'KH575389', '2023/09/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('26815410', 'NV441589', 'KH791545', '2024/05/01', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27030355', 'NV496066', 'KH398577', '2024/08/29', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27091561', 'NV660753', 'KH098035', '2024/07/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27332016', 'NV024982', 'KH576265', '2023/02/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27447085', 'NV659802', 'KH949953', '2024/08/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('27661857', 'NV619036', 'KH348292', '2023/02/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28151554', 'NV905823', 'KH814966', '2023/10/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28318408', 'NV415824', 'KH576265', '2024/05/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28322578', 'NV193469', 'KH694938', '2023/05/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28492331', 'NV078538', 'KH084753', '2024/06/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28670724', 'NV439113', 'KH621641', '2023/11/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('28702515', 'NV901134', 'KH558718', '2023/09/25', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29226413', 'NV019077', 'KH575389', '2024/07/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29345459', 'NV325416', 'KH714662', '2023/09/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29346466', 'NV832790', 'KH562909', '2023/10/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29358314', 'NV180911', 'KH442934', '2024/05/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29381800', 'NV921688', 'KH545916', '2023/12/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29405833', 'NV634749', 'KH025130', '2024/07/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29440514', 'NV376524', 'KH667915', '2024/12/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29790005', 'NV619036', 'KH585269', '2023/10/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29967804', 'NV539311', 'KH344217', '2023/06/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('29988531', 'NV025466', 'KH230361', '2024/09/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30260503', 'NV894914', 'KH285533', '2023/04/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30347601', 'NV890100', 'KH234271', '2024/02/04', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30477187', 'NV650538', 'KH344217', '2023/03/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('30797850', 'NV425018', 'KH761950', '2023/03/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31100814', 'NV303894', 'KH554185', '2023/09/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31206330', 'NV992229', 'KH386338', '2023/10/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31266429', 'NV950327', 'KH575389', '2024/07/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31862596', 'NV594273', 'KH696026', '2024/10/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('31992472', 'NV717819', 'KH545858', '2024/08/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32127415', 'NV413814', 'KH585669', '2023/06/18', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32153563', 'NV454412', 'KH780705', '2024/12/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32167386', 'NV950327', 'KH977771', '2023/12/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32437694', 'NV659671', 'KH761758', '2023/01/26', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32585794', 'NV849197', 'KH529157', '2024/09/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('32737725', 'NV596246', 'KH949953', '2023/11/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('33318683', 'NV732368', 'KH203563', '2024/04/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('33527312', 'NV955885', 'KH460998', '2024/09/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('33744759', 'NV890913', 'KH658936', '2023/10/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34170978', 'NV955706', 'KH941652', '2024/05/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34279066', 'NV240888', 'KH947121', '2024/05/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34913635', 'NV289904', 'KH541552', '2023/11/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('34982804', 'NV325416', 'KH374822', '2023/06/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35254394', 'NV077006', 'KH419510', '2023/02/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35521126', 'NV201665', 'KH947121', '2023/09/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35690416', 'NV253335', 'KH984343', '2024/06/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('35855507', 'NV856226', 'KH773285', '2023/01/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36046393', 'NV659671', 'KH591464', '2024/09/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36101432', 'NV132568', 'KH936694', '2024/02/03', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36260630', 'NV413814', 'KH814108', '2024/03/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36903170', 'NV363798', 'KH446901', '2024/10/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('36911132', 'NV955706', 'KH988988', '2024/06/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37029575', 'NV925832', 'KH760944', '2024/01/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37515146', 'NV196736', 'KH860169', '2023/09/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37620251', 'NV376524', 'KH460998', '2024/12/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('37992672', 'NV340941', 'KH396109', '2024/11/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('38163733', 'NV059671', 'KH557590', '2024/12/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('38240234', 'NV832790', 'KH601439', '2023/02/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('40008069', 'NV979641', 'KH032071', '2024/04/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('40402161', 'NV550817', 'KH237192', '2023/07/03', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('40851325', 'NV044506', 'KH723964', '2023/04/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('41013275', 'NV041942', 'KH558152', '2024/02/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('41288359', 'NV849707', 'KH483866', '2023/10/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('42416206', 'NV510405', 'KH541552', '2023/03/18', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('42523517', 'NV660217', 'KH535109', '2023/05/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('42635597', 'NV955706', 'KH141805', '2023/01/15', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43163666', 'NV450177', 'KH407901', '2024/11/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43618595', 'NV940794', 'KH170428', '2023/02/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43698138', 'NV787213', 'KH780705', '2023/11/11', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('43851343', 'NV429712', 'KH847284', '2023/10/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44118206', 'NV594273', 'KH425172', '2024/10/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44754731', 'NV073871', 'KH121401', '2023/11/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44828717', 'NV594273', 'KH153049', '2023/12/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('44981970', 'NV082912', 'KH083638', '2023/05/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('45159474', 'NV659802', 'KH460998', '2024/01/28', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('45925652', 'NV582109', 'KH344217', '2024/03/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46458379', 'NV391581', 'KH780705', '2024/07/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46548531', 'NV262355', 'KH462707', '2024/10/26', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46608208', 'NV676162', 'KH231668', '2023/02/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46631736', 'NV189822', 'KH390926', '2023/02/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46837887', 'NV732368', 'KH393702', '2024/01/30', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('46870131', 'NV339957', 'KH877635', '2024/03/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47036692', 'NV079311', 'KH437596', '2023/01/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47062940', 'NV010574', 'KH056342', '2023/03/26', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47140966', 'NV568902', 'KH706729', '2023/07/15', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47304726', 'NV078937', 'KH816691', '2024/10/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47389329', 'NV711456', 'KH469917', '2024/04/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47613873', 'NV941014', 'KH677059', '2023/09/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('47889887', 'NV822716', 'KH070493', '2024/03/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48215948', 'NV059671', 'KH870175', '2024/04/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48785703', 'NV790581', 'KH004422', '2024/02/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48948937', 'NV085281', 'KH710303', '2024/03/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('48958287', 'NV264057', 'KH056342', '2024/11/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49092451', 'NV888660', 'KH847284', '2024/11/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49099592', 'NV888660', 'KH365036', '2024/05/03', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49159569', 'NV921688', 'KH112531', '2024/08/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49562547', 'NV447108', 'KH334932', '2023/12/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49838361', 'NV955885', 'KH004422', '2024/01/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('49866923', 'NV659671', 'KH141805', '2024/06/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50135398', 'NV281921', 'KH221463', '2023/02/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50512777', 'NV955885', 'KH315582', '2024/07/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50519849', 'NV288830', 'KH285533', '2024/02/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('50902262', 'NV450177', 'KH819668', '2023/01/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51190625', 'NV659671', 'KH621641', '2024/07/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51472095', 'NV955885', 'KH980984', '2023/02/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51686845', 'NV325416', 'KH697828', '2024/05/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51757291', 'NV594273', 'KH895693', '2024/08/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('51991359', 'NV531991', 'KH987796', '2024/10/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52260834', 'NV264057', 'KH863030', '2023/02/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52263074', 'NV856226', 'KH757285', '2023/11/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52287025', 'NV979641', 'KH391834', '2024/11/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('52546308', 'NV676162', 'KH336007', '2024/09/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53054109', 'NV928013', 'KH986650', '2023/10/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53286397', 'NV650538', 'KH362854', '2023/09/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53455827', 'NV077006', 'KH086552', '2023/12/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('53558431', 'NV955988', 'KH380827', '2024/10/13', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54045234', 'NV945233', 'KH832329', '2023/11/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54309694', 'NV928013', 'KH098035', '2024/01/09', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54324904', 'NV425018', 'KH118901', '2024/09/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54496894', 'NV946657', 'KH341501', '2024/11/23', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54546886', 'NV550817', 'KH577751', '2024/03/03', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54633275', 'NV262355', 'KH541552', '2023/05/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54757028', 'NV376524', 'KH022658', '2024/08/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('54869471', 'NV487204', 'KH872145', '2023/10/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55064095', 'NV408057', 'KH376951', '2024/04/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55367392', 'NV019077', 'KH285533', '2023/11/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55423765', 'NV444738', 'KH339380', '2023/02/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55575314', 'NV660217', 'KH320177', '2023/02/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55603420', 'NV193469', 'KH651808', '2024/08/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('55881706', 'NV264057', 'KH084753', '2024/09/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56232616', 'NV568902', 'KH773307', '2023/04/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56410821', 'NV164312', 'KH236596', '2023/07/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56737208', 'NV789781', 'KH293180', '2023/03/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56776600', 'NV890913', 'KH216038', '2024/03/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('56886025', 'NV582109', 'KH529157', '2024/01/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57139807', 'NV240973', 'KH172746', '2023/11/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57280817', 'NV901134', 'KH564833', '2023/03/31', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57375637', 'NV941014', 'KH128339', '2024/10/22', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57615741', 'NV262355', 'KH582692', '2023/12/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('57618852', 'NV158614', 'KH842523', '2023/01/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('58104633', 'NV383849', 'KH384345', '2023/06/25', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('58195887', 'NV477238', 'KH492275', '2024/02/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('58613381', 'NV940794', 'KH910997', '2023/05/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59091091', 'NV790581', 'KH478576', '2024/06/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59201145', 'NV158614', 'KH621641', '2024/09/13', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59428683', 'NV047107', 'KH796829', '2023/07/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59808596', 'NV592137', 'KH378830', '2023/02/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59829567', 'NV510405', 'KH562909', '2023/07/04', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59875197', 'NV060507', 'KH029547', '2023/04/23', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('59991562', 'NV964113', 'KH900537', '2024/05/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60051135', 'NV574049', 'KH283594', '2024/07/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60051996', 'NV413814', 'KH407901', '2023/11/17', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60606285', 'NV439113', 'KH929292', '2023/06/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60680740', 'NV579268', 'KH234451', '2024/04/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('60993800', 'NV383849', 'KH386338', '2024/04/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61146430', 'NV481500', 'KH153049', '2024/05/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61300575', 'NV835274', 'KH545916', '2024/06/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61304023', 'NV928013', 'KH341501', '2023/09/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61488272', 'NV010574', 'KH382525', '2024/09/14', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61699687', 'NV303957', 'KH070493', '2024/08/18', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('61914355', 'NV193026', 'KH621641', '2023/09/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62143514', 'NV735464', 'KH297971', '2023/08/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62493694', 'NV240888', 'KH819668', '2024/05/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62761266', 'NV439113', 'KH059888', '2024/01/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62764221', 'NV487204', 'KH884843', '2023/08/18', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('62883796', 'NV849707', 'KH098035', '2024/11/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63131447', 'NV277291', 'KH375794', '2024/04/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63510743', 'NV925832', 'KH135574', '2024/05/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63531457', 'NV573727', 'KH128339', '2023/01/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63578463', 'NV510405', 'KH473189', '2023/06/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63623076', 'NV281921', 'KH384345', '2023/03/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('63842193', 'NV240973', 'KH935820', '2024/09/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64064793', 'NV901134', 'KH285098', '2024/09/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64079428', 'NV790581', 'KH666660', '2023/11/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64146299', 'NV025466', 'KH112531', '2023/11/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64765966', 'NV676162', 'KH079281', '2023/08/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('64851539', 'NV596246', 'KH842523', '2023/06/24', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('65491815', 'NV092108', 'KH716623', '2023/10/29', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('65505218', 'NV901134', 'KH494290', '2023/05/09', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('65712213', 'NV787213', 'KH682141', '2023/06/20', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66102208', 'NV634749', 'KH297971', '2023/01/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66188574', 'NV890913', 'KH740368', '2024/01/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66356738', 'NV012052', 'KH920085', '2024/01/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66427363', 'NV639320', 'KH949953', '2024/05/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('66585896', 'NV201665', 'KH820633', '2023/01/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67125189', 'NV271794', 'KH677059', '2024/03/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67253718', 'NV164312', 'KH958880', '2024/06/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67273520', 'NV297438', 'KH374822', '2023/01/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67415180', 'NV659671', 'KH575389', '2024/04/11', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67493116', 'NV367893', 'KH518463', '2023/11/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67696349', 'NV659802', 'KH460998', '2024/07/28', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67882602', 'NV223401', 'KH006633', '2024/05/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67888864', 'NV574049', 'KH599858', '2024/09/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('67999316', 'NV480270', 'KH526686', '2024/07/23', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68141332', 'NV660753', 'KH149810', '2023/10/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68212839', 'NV660217', 'KH409572', '2024/03/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68488171', 'NV521642', 'KH132801', '2024/09/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68554816', 'NV894914', 'KH084013', '2023/05/13', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68593258', 'NV240973', 'KH876167', '2024/05/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68681176', 'NV060507', 'KH237493', '2024/03/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68807531', 'NV619036', 'KH713210', '2023/06/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('68956633', 'NV790581', 'KH544891', '2024/01/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69073457', 'NV955988', 'KH621641', '2024/02/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69100259', 'NV010574', 'KH120054', '2024/01/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69194990', 'NV950327', 'KH442934', '2023/04/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69309970', 'NV122335', 'KH350452', '2023/09/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('69808473', 'NV676162', 'KH145038', '2024/02/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('70272289', 'NV303957', 'KH172746', '2023/12/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('70328718', 'NV297438', 'KH760944', '2024/08/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('70377200', 'NV850462', 'KH204348', '2024/09/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71210252', 'NV408057', 'KH592532', '2023/08/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71368887', 'NV303894', 'KH384345', '2023/08/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71801009', 'NV992229', 'KH558718', '2023/03/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('71909829', 'NV850038', 'KH236596', '2023/09/18', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72205127', 'NV928013', 'KH017103', '2024/09/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72230777', 'NV524840', 'KH147192', '2024/03/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72294479', 'NV888660', 'KH066621', '2023/01/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('72418778', 'NV619036', 'KH714662', '2024/12/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('73758764', 'NV941879', 'KH977771', '2023/03/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74460311', 'NV178173', 'KH306439', '2023/05/23', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74686265', 'NV480270', 'KH056342', '2023/09/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74867866', 'NV429712', 'KH965543', '2024/04/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74869186', 'NV105604', 'KH958880', '2024/05/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('74946433', 'NV531991', 'KH084013', '2024/11/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75645929', 'NV992229', 'KH772577', '2024/09/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75689282', 'NV650538', 'KH914683', '2023/03/09', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75750998', 'NV160815', 'KH227910', '2024/06/21', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75953436', 'NV161099', 'KH227910', '2023/11/14', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('75960033', 'NV711456', 'KH949953', '2024/07/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('77335529', 'NV057942', 'KH791545', '2023/11/21', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('77379402', 'NV339957', 'KH694938', '2024/03/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('77555844', 'NV620763', 'KH791759', '2024/02/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78412233', 'NV650538', 'KH522691', '2024/07/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78518151', 'NV193469', 'KH796829', '2023/07/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78864629', 'NV158614', 'KH460521', '2024/01/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78920552', 'NV453523', 'KH291338', '2024/05/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('78967747', 'NV797940', 'KH098035', '2023/03/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79177322', 'NV376524', 'KH987796', '2024/09/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79396331', 'NV521642', 'KH437409', '2024/10/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79652274', 'NV303199', 'KH549396', '2023/11/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('79746616', 'NV711456', 'KH562909', '2024/03/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('80506782', 'NV480270', 'KH870175', '2024/03/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('80935436', 'NV012052', 'KH119243', '2024/07/30', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('80962217', 'NV164312', 'KH483866', '2023/09/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81015092', 'NV964113', 'KH832329', '2023/12/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81073581', 'NV592137', 'KH157277', '2024/06/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81231428', 'NV496066', 'KH154664', '2024/03/30', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81314976', 'NV085281', 'KH716623', '2023/07/31', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81477356', 'NV392010', 'KH099791', '2023/12/09', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81674784', 'NV888660', 'KH128603', '2024/07/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81873049', 'NV979641', 'KH380827', '2023/12/08', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('81958720', 'NV343692', 'KH087105', '2024/09/02', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82122385', 'NV875495', 'KH958880', '2023/11/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82163171', 'NV941014', 'KH714295', '2023/08/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82696945', 'NV415824', 'KH453142', '2023/11/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82704385', 'NV738399', 'KH876167', '2024/04/23', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('82717794', 'NV391581', 'KH057137', '2023/10/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83042107', 'NV675961', 'KH545858', '2023/06/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83054764', 'NV180911', 'KH355802', '2024/06/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83191185', 'NV077006', 'KH706729', '2023/03/03', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83298123', 'NV480270', 'KH919695', '2023/12/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83379534', 'NV303199', 'KH441817', '2023/01/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83380519', 'NV645678', 'KH179505', '2024/06/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83413062', 'NV025466', 'KH154664', '2023/02/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83447776', 'NV392010', 'KH362680', '2023/11/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83481842', 'NV077006', 'KH355802', '2023/01/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('83960238', 'NV890100', 'KH710303', '2024/08/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('84424932', 'NV596246', 'KH621641', '2024/03/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('84707385', 'NV717819', 'KH013100', '2024/12/22', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85337194', 'NV079311', 'KH558152', '2024/04/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85482795', 'NV850038', 'KH407901', '2023/07/02', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85770297', 'NV433504', 'KH975326', '2024/03/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85857885', 'NV925832', 'KH119243', '2023/09/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('85967836', 'NV905823', 'KH757285', '2024/02/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('86161532', 'NV955885', 'KH147192', '2024/04/14', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('86182227', 'NV789781', 'KH391834', '2024/12/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87076460', 'NV531991', 'KH823647', '2023/08/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87257749', 'NV264057', 'KH895693', '2023/06/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87498485', 'NV098182', 'KH522691', '2024/12/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87615837', 'NV408057', 'KH658936', '2024/09/26', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87766736', 'NV950327', 'KH903096', '2024/09/27', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87835257', 'NV894914', 'KH522691', '2023/09/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('87898902', 'NV539311', 'KH700174', '2023/10/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88064742', 'NV440528', 'KH683530', '2024/09/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88087511', 'NV496066', 'KH740368', '2024/12/11', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88261127', 'NV440528', 'KH529157', '2024/12/15', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88346856', 'NV797940', 'KH008583', '2024/04/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88660704', 'NV164312', 'KH919695', '2024/09/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88707289', 'NV132568', 'KH099791', '2024/06/11', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88828477', 'NV339957', 'KH158297', '2023/09/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88853460', 'NV441589', 'KH018367', '2023/05/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88855917', 'NV160815', 'KH396109', '2024/08/14', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('88880729', 'NV281921', 'KH773285', '2024/09/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89096598', 'NV940794', 'KH790357', '2023/10/06', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89301934', 'NV059671', 'KH376951', '2024/02/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89445564', 'NV383849', 'KH271569', '2023/11/09', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('89461258', 'NV303957', 'KH714662', '2023/01/19', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90079336', 'NV440528', 'KH786340', '2024/10/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90317087', 'NV057942', 'KH545858', '2023/07/30', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90351583', 'NV367893', 'KH563902', '2023/11/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90431741', 'NV850038', 'KH375073', '2023/10/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90649500', 'NV132568', 'KH088786', '2023/06/20', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90787904', 'NV955885', 'KH529157', '2024/11/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90831040', 'NV496066', 'KH666660', '2024/04/22', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90988734', 'NV650538', 'KH494290', '2023/02/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90994110', 'NV201665', 'KH096988', '2023/09/16', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('90999927', 'NV161099', 'KH386338', '2023/10/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91023762', 'NV098182', 'KH817290', '2023/12/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91144158', 'NV835274', 'KH375317', '2023/02/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91236619', 'NV433504', 'KH044397', '2023/12/26', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91249247', 'NV057942', 'KH773285', '2023/02/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91447270', 'NV921688', 'KH006633', '2023/03/23', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91617761', 'NV619036', 'KH748649', '2024/07/17', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91925109', 'NV496066', 'KH128603', '2023/05/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('91947888', 'NV573727', 'KH170428', '2023/11/10', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92033882', 'NV077006', 'KH575389', '2024/07/11', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92039250', 'NV325416', 'KH170428', '2023/05/23', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92077884', 'NV659802', 'KH008583', '2023/04/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92391942', 'NV639320', 'KH462707', '2024/06/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92488546', 'NV425018', 'KH481886', '2023/06/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92612348', 'NV454412', 'KH672845', '2024/04/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92827922', 'NV594273', 'KH027997', '2024/11/04', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('92951368', 'NV308774', 'KH099823', '2024/06/08', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93399362', 'NV242498', 'KH939840', '2024/04/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93543773', 'NV941014', 'KH362854', '2024/08/07', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93795457', 'NV510405', 'KH535109', '2024/02/12', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('93961964', 'NV592137', 'KH039286', '2024/05/13', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94198005', 'NV223401', 'KH473189', '2024/02/07', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94386793', 'NV060507', 'KH496697', '2023/10/15', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94398535', 'NV477238', 'KH830363', '2024/10/10', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94687846', 'NV439113', 'KH714662', '2024/02/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('94830505', 'NV955885', 'KH518463', '2024/11/05', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('95517222', 'NV888660', 'KH131158', '2024/04/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('95975109', 'NV079311', 'KH697088', '2024/11/12', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96037462', 'NV477238', 'KH707432', '2024/12/15', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96076090', 'NV367893', 'KH283594', '2023/05/31', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96240176', 'NV178173', 'KH669308', '2023/06/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96311209', 'NV481500', 'KH782287', '2023/06/21', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96604089', 'NV044506', 'KH013100', '2024/06/16', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('96675854', 'NV454412', 'KH491026', '2023/12/24', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97495281', 'NV059671', 'KH707432', '2023/08/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97627792', 'NV596246', 'KH153049', '2023/12/05', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97655772', 'NV518097', 'KH518463', '2023/03/14', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97679853', 'NV659802', 'KH709442', '2023/09/29', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('97772063', 'NV288830', 'KH860169', '2023/04/01', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98257461', 'NV047107', 'KH370303', '2024/01/23', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98332302', 'NV550817', 'KH414310', '2023/09/03', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98448395', 'NV303894', 'KH536661', '2023/08/25', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('98845092', 'NV835274', 'KH380827', '2024/10/06', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99149331', 'NV832790', 'KH291338', '2024/03/28', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99168318', 'NV955988', 'KH374203', '2024/10/27', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99454089', 'NV343692', 'KH536661', '2023/12/19', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99551548', 'NV044506', 'KH904366', '2024/02/22', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99579686', 'NV964113', 'KH018367', '2024/06/29', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99619728', 'NV240973', 'KH302564', '2024/01/25', 0);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99675600', 'NV281921', 'KH094387', '2024/06/13', 1);
insert into HOADON (MAHD, MANV, MAKH, NGAYLAP, TINHTRANG) values ('99715059', 'NV660217', 'KH121401', '2023/03/23', 0);


GO
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NGAM0637', 'W', 'VP 100', '30260503', 270, '$4854.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VCNS0117', 'J', 'RS 632', '88707289', 190, '$592.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YGIU9637', 'Y', 'PI 359', '45159474', 190, '$1735.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JBTY7093', 'Y', 'DY 653', '36260630', 157, '$2845.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WKZH9372', 'W', 'UL 806', '81873049', 201, '$818.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EHTT7007', 'W', 'XY 772', '40402161', 225, '$4944.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JWTO5871', 'Y', 'SW 408', '67253718', 156, '$420.04');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GUTL8360', 'Y', 'KG 314', '84707385', 168, '$1638.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GDGZ9012', 'W', 'CS 257', '59829567', 94, '$3791.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YMTP9561', 'W', 'UF 966', '46837887', 125, '$1625.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KFII4617', 'W', 'GX 679', '50512777', 7, '$3029.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZWDG6199', 'W', 'CM 255', '58104633', 37, '$3641.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RSKN6887', 'F', 'PK 064', '45159474', 220, '$2456.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LFZS3462', 'Y', 'LV 508', '43698138', 245, '$3516.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IJFO4617', 'J', 'JW 088', '19249690', 252, '$2086.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LBKO6853', 'Y', 'EB 303', '41013275', 14, '$648.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YGPC1582', 'W', 'FH 258', '65505218', 104, '$4508.77');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GAMA3279', 'Y', 'JW 088', '17387584', 101, '$1920.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YYJK5389', 'W', 'VV 600', '97627792', 115, '$577.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RXCZ8916', 'W', 'YF 362', '05949964', 26, '$534.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HMDC4968', 'Y', 'LI 649', '10935131', 263, '$3807.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YFYT2065', 'F', 'IG 452', '99168318', 144, '$899.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VZOA5891', 'W', 'QZ 396', '85482795', 235, '$1444.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UDDW3876', 'J', 'BZ 794', '99551548', 173, '$2892.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LWQD0042', 'W', 'YX 198', '05502162', 126, '$2136.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DZHW9271', 'W', 'CK 021', '01977459', 41, '$4412.75');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PUBL3575', 'W', 'XY 772', '02998601', 259, '$4236.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SREK4951', 'Y', 'MG 930', '48958287', 32, '$4203.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VTLM0661', 'W', 'GW 845', '45159474', 109, '$1539.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VTBU9826', 'J', 'SO 116', '16531754', 34, '$1478.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('STLU4171', 'Y', 'LP 806', '82696945', 171, '$3213.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KVKS7228', 'F', 'US 277', '21932175', 81, '$3364.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PZMF6937', 'W', 'FK 002', '40402161', 165, '$4775.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GIEH2324', 'W', 'RS 632', '06062676', 191, '$4813.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RUOJ3423', 'W', 'CU 286', '83054764', 210, '$3095.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BVAK1497', 'J', 'SJ 060', '95975109', 165, '$1427.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SEND6162', 'J', 'IH 336', '36260630', 14, '$1740.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ATQN5183', 'Y', 'LU 202', '46458379', 144, '$2518.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FRWJ4212', 'Y', 'AC 133', '60051135', 211, '$1002.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DWAB1973', 'F', 'AN 989', '90351583', 171, '$842.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RGWP9818', 'Y', 'VB 885', '15095037', 33, '$212.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PJIW1330', 'W', 'RS 632', '60606285', 109, '$4001.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SHEI9072', 'W', 'YF 362', '60051996', 27, '$1853.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TQOO8378', 'W', 'UZ 409', '99168318', 20, '$1621.65');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PLXB3773', 'Y', 'WK 651', '04679087', 175, '$2478.65');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ETRB5124', 'J', 'FT 190', '65712213', 77, '$3955.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FGZM3150', 'J', 'VA 877', '31992472', 260, '$4249.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YJNF3255', 'W', 'UF 966', '46608208', 224, '$4363.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XSXU9673', 'W', 'RS 632', '58613381', 160, '$4827.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OFRP8220', 'Y', 'SE 323', '93961964', 235, '$1187.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FSES5313', 'Y', 'LZ 930', '21163258', 125, '$478.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MOXA3840', 'Y', 'CM 255', '01293073', 200, '$3711.47');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SFDG7895', 'W', 'UD 378', '11821755', 246, '$235.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FIXB6329', 'Y', 'FR 949', '44981970', 171, '$4110.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FCXB0957', 'Y', 'SE 323', '43698138', 288, '$4425.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZNIJ9936', 'Y', 'MG 930', '88855917', 257, '$2645.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZLIF0888', 'J', 'VA 877', '06317278', 176, '$4644.08');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VYBA0007', 'J', 'LZ 930', '61146430', 239, '$3843.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VVPP9254', 'Y', 'GH 241', '63131447', 161, '$2723.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SLDK6095', 'W', 'MU 795', '91236619', 279, '$1209.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OOSY4311', 'J', 'WK 651', '42523517', 171, '$1072.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WPAU0784', 'Y', 'FT 589', '24139505', 246, '$4739.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DXEJ5813', 'W', 'FT 589', '60606285', 212, '$4765.35');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ONSL2071', 'W', 'AN 989', '11057658', 214, '$1935.84');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FLYZ2752', 'Y', 'VJ 397', '34913635', 197, '$4472.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OIND4278', 'W', 'IA 834', '32167386', 92, '$4758.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MKAZ4509', 'Y', 'YX 198', '93961964', 246, '$4205.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TJRU7129', 'J', 'RJ 751', '22376000', 62, '$4874.08');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JVBP7473', 'Y', 'LX 199', '26677987', 167, '$4097.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FAEM1922', 'Y', 'CM 255', '15250752', 139, '$2843.80');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MWHU6691', 'W', 'TI 992', '90999927', 224, '$2139.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DQYP3273', 'J', 'NA 077', '10174845', 109, '$2281.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IDJM8341', 'Y', 'FT 589', '49866923', 252, '$2923.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WGUC6340', 'J', 'VB 795', '29405833', 9, '$443.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JZTY6565', 'J', 'DM 930', '45925652', 248, '$2318.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZEON3037', 'Y', 'HD 186', '31266429', 247, '$271.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZCYV4611', 'F', 'SU 627', '23127223', 77, '$4313.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YVNZ3926', 'J', 'EA 714', '93961964', 259, '$2667.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OHPQ8139', 'W', 'MQ 793', '17168656', 193, '$696.36');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YCHD0371', 'W', 'LU 202', '19453685', 55, '$2807.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QKWG3858', 'W', 'YP 747', '91023762', 223, '$1891.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RKVH6801', 'Y', 'GH 241', '83191185', 122, '$4167.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UJHY2413', 'W', 'FQ 490', '68593258', 128, '$3767.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZNMI0444', 'F', 'ZO 430', '81958720', 260, '$1108.78');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MHBU2421', 'J', 'AT 362', '69309970', 290, '$3588.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DHRM5883', 'W', 'AG 553', '91925109', 180, '$2681.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JOYN8985', 'J', 'OL 737', '05146450', 35, '$1678.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MFUS9524', 'J', 'CI 813', '70272289', 24, '$3076.33');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YUMW8707', 'J', 'LZ 930', '93961964', 24, '$4321.79');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZIEG0335', 'J', 'CK 021', '91925109', 45, '$1143.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RCYU9283', 'Y', 'IX 315', '25142090', 155, '$2928.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OKUW7185', 'Y', 'ST 147', '40402161', 29, '$3996.97');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MGBF6471', 'J', 'KT 165', '06132492', 186, '$1382.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SJGY5397', 'J', 'EE 682', '35521126', 151, '$4658.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AFYZ0310', 'W', 'OC 854', '13227974', 227, '$1246.35');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YGJE9321', 'Y', 'SW 408', '52546308', 188, '$2343.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SZZU2924', 'J', 'NR 260', '27030355', 129, '$120.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XVVE9977', 'F', 'PI 349', '18226382', 82, '$1297.69');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QFYL9105', 'W', 'KV 831', '15139654', 41, '$565.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TNNV2959', 'W', 'RX 159', '74460311', 173, '$1729.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AKBU6519', 'W', 'SJ 060', '02704470', 284, '$3937.03');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KZQM8146', 'J', 'GV 052', '88346856', 139, '$4414.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QGDR1659', 'J', 'QO 997', '79396331', 278, '$3235.97');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LLKC7258', 'W', 'ZH 266', '52546308', 119, '$1701.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QRND8240', 'J', 'HD 186', '25535597', 236, '$1871.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LCCS4246', 'Y', 'CK 021', '50135398', 45, '$4092.77');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FDYV9345', 'F', 'IX 315', '88087511', 60, '$754.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IUEF2947', 'W', 'EA 805', '75953436', 204, '$251.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RWNZ2793', 'J', 'BL 389', '92033882', 93, '$2361.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VMKE5003', 'Y', 'MP 271', '49838361', 297, '$3833.81');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SFHO7146', 'J', 'ML 770', '17056136', 248, '$4060.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KURU3249', 'Y', 'PI 359', '68681176', 22, '$1845.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SARR3399', 'Y', 'IX 315', '99168318', 125, '$1835.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MJBZ3486', 'Y', 'NA 077', '18719517', 280, '$3593.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SSZX9805', 'W', 'BC 789', '26010133', 233, '$445.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BNUC2238', 'Y', 'YR 162', '67888864', 162, '$1341.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OIWI8017', 'Y', 'LU 202', '91447270', 179, '$3896.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BUSY0326', 'F', 'XK 113', '89445564', 200, '$4188.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TLQC8733', 'Y', 'PE 344', '88828477', 157, '$4343.67');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XTOS8111', 'J', 'HE 072', '52287025', 212, '$209.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NCHV1466', 'W', 'TV 344', '34982804', 150, '$252.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JEET7090', 'W', 'CM 255', '91144158', 155, '$3663.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FIUU1638', 'W', 'CD 263', '59808596', 148, '$4532.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DPFE8391', 'W', 'AC 133', '61146430', 271, '$4525.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NZCG8624', 'W', 'RG 468', '16531754', 140, '$2438.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UBUN9346', 'J', 'LW 020', '54324904', 233, '$3142.08');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WXJX1143', 'Y', 'WI 057', '11057658', 105, '$4091.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KUDK8170', 'J', 'AG 553', '26010133', 117, '$2238.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GXXW1285', 'W', 'LZ 930', '13528822', 190, '$3551.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IKXG0448', 'W', 'DM 930', '05469109', 234, '$1842.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HEUN1689', 'Y', 'SO 116', '44828717', 283, '$3461.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RPYI4011', 'F', 'MG 930', '60993800', 130, '$2387.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IOPQ2181', 'W', 'QS 839', '88346856', 30, '$1644.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FXUE1911', 'Y', 'FM 573', '14258585', 172, '$157.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NMGF8750', 'W', 'ID 364', '28318408', 274, '$967.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NBIL7407', 'J', 'EB 303', '01616005', 186, '$705.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YYDF1445', 'W', 'VZ 503', '36046393', 13, '$910.35');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FEXB0948', 'W', 'ST 180', '23760940', 163, '$396.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BBHQ4708', 'W', 'CM 255', '53558431', 136, '$814.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UTEP6493', 'F', 'TV 344', '78412233', 92, '$2173.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KJLI1016', 'J', 'QF 239', '60051996', 289, '$1553.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NXSE7999', 'W', 'ST 180', '57375637', 125, '$1563.03');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CGNL5835', 'Y', 'EN 334', '18719517', 95, '$3634.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('USID3011', 'J', 'VB 885', '05596399', 10, '$2412.33');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JTKR3946', 'J', 'EI 901', '02998601', 156, '$1685.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DFXE9368', 'J', 'JS 595', '98448395', 201, '$1299.37');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FXFY7287', 'F', 'CU 286', '01977459', 155, '$217.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('INWE4138', 'W', 'KB 938', '61488272', 279, '$3899.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UQIC9133', 'J', 'VB 885', '92391942', 6, '$2297.49');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IFRC3577', 'Y', 'YL 505', '26815410', 192, '$1655.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TXIR0439', 'W', 'CD 263', '41013275', 116, '$4653.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EENJ8606', 'W', 'GG 179', '68681176', 282, '$2313.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EUPV9956', 'J', 'PJ 001', '88087511', 2, '$4692.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZOVH3338', 'J', 'MU 795', '54633275', 140, '$4178.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MCRT2469', 'J', 'US 277', '54757028', 289, '$465.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NKFB2911', 'Y', 'RG 468', '31862596', 74, '$3226.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ABBL1910', 'F', 'NQ 204', '30260503', 81, '$3228.13');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZQAC5978', 'W', 'QF 607', '37029575', 103, '$3968.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EESF0569', 'Y', 'YX 198', '92033882', 202, '$918.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NDLK8634', 'Y', 'NS 674', '84707385', 60, '$1684.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EKLK1130', 'W', 'CS 285', '29346466', 186, '$4120.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VTDD7443', 'Y', 'ZO 430', '90317087', 203, '$385.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FCPP0869', 'W', 'LX 199', '94687846', 4, '$3282.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LSCO1356', 'J', 'GT 100', '02704470', 136, '$1743.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ONFL3221', 'W', 'VV 363', '67888864', 171, '$3072.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DHAW1993', 'W', 'VR 146', '05596399', 271, '$180.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IWVH2926', 'W', 'QH 964', '29358314', 28, '$4314.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XJOA2035', 'W', 'MQ 793', '22610247', 296, '$971.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZTXZ4644', 'W', 'NR 260', '09685222', 269, '$1235.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CPCA7232', 'W', 'LZ 930', '15662805', 107, '$4687.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LZEZ5320', 'J', 'FT 190', '62143514', 286, '$1245.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TFPY9505', 'W', 'UF 966', '99675600', 258, '$3425.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IAPN9603', 'J', 'LW 020', '34982804', 164, '$2883.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UELX6710', 'Y', 'VN 139', '41013275', 92, '$2264.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WOFX5857', 'J', 'CD 263', '58613381', 186, '$4067.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DOCV9678', 'Y', 'PK 064', '67415180', 191, '$135.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VGYB4337', 'Y', 'DE 995', '55575314', 187, '$4497.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SUVE3545', 'Y', 'OC 854', '61488272', 35, '$2155.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RFAU4078', 'W', 'ML 770', '91236619', 60, '$783.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LDIF4043', 'J', 'MP 271', '58104633', 19, '$4200.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TQQC8557', 'J', 'PJ 001', '18045997', 220, '$3266.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EYPF9062', 'F', 'MQ 793', '43618595', 59, '$63.17');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NKCV8564', 'Y', 'HD 186', '28151554', 266, '$4570.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GMMI0449', 'Y', 'PK 064', '80506782', 273, '$2483.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YUFQ6675', 'J', 'RI 271', '16346188', 41, '$2853.04');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NTUO9128', 'W', 'FH 258', '22610247', 134, '$1435.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PNYN0167', 'J', 'SH 048', '69100259', 116, '$3536.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VGMB6736', 'Y', 'JZ 483', '91447270', 103, '$1876.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JXAD9851', 'Y', 'UL 806', '22234337', 94, '$1135.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EFVP1493', 'W', 'YL 505', '65491815', 183, '$2682.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JJXK2713', 'W', 'LX 199', '26787626', 203, '$3588.66');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZDDA1353', 'W', 'UZ 409', '33744759', 100, '$462.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YXRA8987', 'Y', 'RJ 751', '04679087', 159, '$2108.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CKUK6986', 'Y', 'VA 132', '68956633', 122, '$4313.41');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PNXY3172', 'J', 'RI 271', '91947888', 103, '$3381.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IHCY0659', 'J', 'ZP 863', '72230777', 134, '$2622.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZVRQ7945', 'W', 'QZ 396', '46458379', 20, '$3188.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JSWB4716', 'J', 'FT 190', '15308723', 60, '$3120.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RXKS5228', 'Y', 'FW 269', '16752375', 58, '$4268.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DPCF0450', 'J', 'DY 653', '15076148', 104, '$1018.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SYOC6448', 'Y', 'ZP 863', '86161532', 87, '$2640.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SYGH0528', 'W', 'KG 314', '07542827', 268, '$4698.47');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PYKJ9301', 'J', 'LU 202', '21163258', 139, '$3814.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CLBS6716', 'W', 'GH 241', '94198005', 3, '$4400.84');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XRMD6180', 'W', 'MH 757', '62883796', 184, '$1734.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XEJX8642', 'W', 'CM 255', '20502716', 142, '$4884.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VUNK6195', 'Y', 'MU 795', '93795457', 56, '$48.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JJGJ3160', 'F', 'VZ 667', '40402161', 272, '$348.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MDIW7255', 'J', 'XK 113', '96675854', 199, '$3702.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OOBY9114', 'W', 'CS 257', '88261127', 299, '$48.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IDFQ5422', 'W', 'YF 362', '15324566', 87, '$1431.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WTVD8934', 'J', 'ZH 266', '19249690', 78, '$4382.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AKET7470', 'J', 'ND 911', '42635597', 262, '$3923.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KVCP8055', 'J', 'LU 202', '94386793', 114, '$3647.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HBRU5329', 'J', 'SU 627', '81958720', 42, '$712.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VHZT6830', 'Y', 'VI 246', '88346856', 56, '$92.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MCEW3600', 'Y', 'DV 657', '40402161', 97, '$4843.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MHPF5728', 'W', 'OT 330', '81477356', 77, '$4039.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DUET5622', 'J', 'MD 784', '62493694', 272, '$4863.08');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IHKE8874', 'Y', 'ML 770', '35254394', 22, '$2349.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ARAX0794', 'J', 'KB 938', '69100259', 50, '$3724.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BVKR7704', 'W', 'UX 023', '93399362', 261, '$4468.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EEVW7230', 'W', 'EE 682', '63510743', 176, '$3297.39');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UOTX4453', 'Y', 'DZ 316', '65712213', 133, '$981.52');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PKKH5631', 'J', 'EL 557', '29440514', 134, '$762.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KGXR4899', 'J', 'LZ 930', '66585896', 94, '$975.36');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OAUB3282', 'Y', 'XL 786', '38163733', 52, '$3444.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MHUN1186', 'J', 'HE 072', '60051135', 257, '$4430.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RIOA3485', 'Y', 'GW 845', '83054764', 155, '$802.13');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GLWV1720', 'W', 'ZH 266', '15324566', 188, '$4247.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SWVT4348', 'W', 'JK 999', '10179483', 226, '$787.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DRJK2119', 'W', 'NQ 204', '16466095', 62, '$3927.08');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XDIN9602', 'Y', 'KX 851', '69194990', 12, '$3485.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WMJM0800', 'Y', 'KG 314', '87835257', 3, '$2081.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HDSN4665', 'Y', 'YF 362', '11057658', 207, '$1322.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LXTM1235', 'W', 'NR 260', '57280817', 180, '$4690.04');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HEQQ8442', 'J', 'WB 728', '29440514', 197, '$1860.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LJMX9072', 'Y', 'XL 786', '73758764', 114, '$313.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GMJT4496', 'Y', 'QF 239', '42416206', 280, '$1386.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CTGL8671', 'Y', 'UZ 409', '61699687', 95, '$2416.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TIOO9017', 'W', 'IG 452', '23273614', 59, '$4364.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GXHO7096', 'J', 'FT 589', '81314976', 207, '$2582.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VVQV5708', 'Y', 'QW 044', '03227540', 203, '$2247.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CTHV2575', 'W', 'UX 023', '87615837', 248, '$2827.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YOSK0453', 'Y', 'AN 989', '05396256', 109, '$4209.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YEPB3774', 'Y', 'YL 505', '60680740', 300, '$1418.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FDSE8499', 'Y', 'UF 966', '10174845', 51, '$849.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CZIE4167', 'W', 'VB 795', '13528822', 97, '$152.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DLGJ1445', 'Y', 'PE 344', '67882602', 199, '$430.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GZUB4838', 'W', 'MP 271', '26815410', 254, '$4127.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UAKQ4780', 'J', 'QF 239', '74686265', 283, '$3262.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DNIP9595', 'Y', 'ZH 266', '48215948', 128, '$2368.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UZBY2436', 'J', 'EN 334', '56886025', 246, '$4768.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IOZD5440', 'J', 'CS 257', '29790005', 296, '$4945.99');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WWKE9791', 'F', 'TI 992', '85482795', 39, '$4003.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NBER9243', 'F', 'EL 557', '93543773', 169, '$1372.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZZQF9625', 'Y', 'ND 911', '30797850', 177, '$553.08');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NDSZ2968', 'W', 'FT 215', '34913635', 129, '$4464.99');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LPYL4275', 'J', 'JR 712', '18282997', 250, '$222.36');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IDTA7868', 'J', 'WF 431', '67493116', 256, '$3950.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QQLJ1519', 'J', 'CS 285', '22535180', 96, '$4423.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZTOC2261', 'W', 'SW 408', '63842193', 253, '$1127.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UIPA9396', 'W', 'OC 854', '36101432', 24, '$4390.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MMOF0213', 'W', 'ZJ 357', '20765138', 257, '$3514.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FLUG7544', 'Y', 'UI 252', '63531457', 63, '$3829.36');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DOHR5348', 'J', 'EA 714', '91617761', 212, '$2363.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TSBL0942', 'W', 'AH 272', '05346638', 19, '$4305.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BUQP4331', 'J', 'OT 330', '03227540', 23, '$2937.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JOWR7909', 'Y', 'TP 671', '85857885', 195, '$2675.52');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UVXC2220', 'W', 'GX 201', '78412233', 296, '$203.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QEUS4216', 'Y', 'UF 966', '49099592', 71, '$1757.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MHJI3693', 'W', 'GP 148', '81873049', 201, '$280.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UBEK8354', 'Y', 'QF 607', '21000317', 155, '$4923.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AFII2076', 'W', 'XK 113', '61914355', 58, '$1712.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OJTT1300', 'W', 'DF 740', '62143514', 31, '$3268.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SINZ4713', 'Y', 'XF 119', '03909266', 8, '$4804.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KPHX0740', 'Y', 'VA 132', '27447085', 247, '$1415.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TPGT6871', 'J', 'UD 378', '97655772', 161, '$995.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MPIX3997', 'W', 'GT 100', '50512777', 255, '$4179.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QVKD2241', 'F', 'YP 747', '25788579', 256, '$339.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JGZK4351', 'Y', 'MG 930', '97627792', 138, '$4077.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PFWM3431', 'Y', 'CU 216', '46837887', 245, '$4226.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HIVP4859', 'J', 'RG 468', '82163171', 205, '$1948.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ANOS8089', 'J', 'PK 064', '32437694', 194, '$4372.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SZRH6641', 'Y', 'SO 116', '83054764', 44, '$4903.03');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SJXV4990', 'W', 'AG 553', '32127415', 102, '$2776.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PYCR9678', 'Y', 'EB 303', '56410821', 74, '$794.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QDAQ0621', 'J', 'DY 653', '88707289', 283, '$2031.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MBCE2708', 'W', 'QF 474', '15250752', 256, '$3320.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ODWN6384', 'W', 'UD 378', '99579686', 111, '$3603.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DFOY0518', 'J', 'ZH 266', '71909829', 264, '$2023.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NAZD9568', 'W', 'VP 100', '28670724', 285, '$2446.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SOKQ2552', 'Y', 'KV 831', '33318683', 133, '$4042.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LVBR0112', 'J', 'SU 627', '50135398', 284, '$4371.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BHGG0493', 'J', 'DF 740', '15076148', 35, '$1039.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TKTZ4230', 'Y', 'IG 452', '59091091', 269, '$2033.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BDNQ9557', 'F', 'IJ 564', '97679853', 200, '$690.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EMXD9671', 'W', 'ZE 184', '56232616', 125, '$1513.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UTKI9082', 'W', 'VZ 667', '75645929', 153, '$3231.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SETU1366', 'Y', 'VH 352', '99579686', 125, '$3022.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KWNA3418', 'W', 'VB 795', '86182227', 45, '$2190.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EFIH2883', 'Y', 'YP 305', '99675600', 119, '$4005.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZAEL8295', 'J', 'LI 649', '99579686', 170, '$4358.35');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IIJC1676', 'Y', 'FM 573', '17443686', 139, '$2551.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PBYO5292', 'F', 'VP 100', '87257749', 299, '$1707.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EOGJ4381', 'F', 'EI 901', '96675854', 93, '$780.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WSLU5784', 'J', 'FW 269', '07199807', 20, '$627.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GRTN7076', 'Y', 'VV 600', '17387584', 115, '$423.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GFMQ0756', 'W', 'YR 162', '00140987', 282, '$3335.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SORK8887', 'F', 'ST 180', '33318683', 169, '$4097.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YUSP9094', 'J', 'SO 116', '57618852', 250, '$3993.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BFDM8108', 'J', 'EA 714', '57375637', 25, '$1698.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OLWF8011', 'J', 'CC 450', '17815063', 95, '$2442.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WMTP9426', 'Y', 'CK 021', '46458379', 145, '$1234.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FFFM5444', 'W', 'PJ 647', '59201145', 202, '$712.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DEFR7519', 'W', 'QF 239', '38163733', 47, '$291.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TYPZ2105', 'Y', 'GX 679', '47889887', 274, '$833.66');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ERRA3282', 'Y', 'JR 712', '57139807', 237, '$3678.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SRXR1369', 'W', 'XK 113', '58613381', 272, '$326.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XSSJ6355', 'F', 'VN 139', '50512777', 21, '$4991.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KIAT5046', 'W', 'XF 402', '46458379', 267, '$751.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IOAH9618', 'Y', 'QB 429', '13740822', 196, '$4616.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LTRP4735', 'W', 'GH 241', '63578463', 142, '$884.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XFNR6840', 'J', 'SH 048', '13227974', 12, '$2556.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NYBG5459', 'W', 'FZ 441', '99168318', 172, '$4343.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RNLA6356', 'J', 'IH 336', '64851539', 85, '$3536.81');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GGRX9171', 'J', 'VA 877', '25535597', 94, '$563.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CJVJ7581', 'Y', 'YK 442', '32127415', 71, '$607.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SYUQ5994', 'F', 'JR 712', '59808596', 228, '$4669.16');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JDIN4739', 'J', 'RG 468', '59991562', 72, '$3476.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EDTY4121', 'J', 'PE 344', '44828717', 298, '$1522.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FXTT9045', 'J', 'GX 201', '47140966', 201, '$2485.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QSGI9124', 'Y', 'MF 795', '27661857', 170, '$3521.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YKDI1707', 'J', 'VA 877', '27091561', 258, '$338.56');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VTIG8943', 'W', 'NR 260', '08184228', 260, '$1898.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IPKV9339', 'W', 'CC 450', '17815063', 18, '$4604.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DTPI7643', 'J', 'FK 002', '90431741', 221, '$3652.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WXJX2680', 'F', 'ZG 279', '44828717', 64, '$500.04');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GRVH7568', 'J', 'IF 068', '56886025', 219, '$2076.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OIJV3277', 'Y', 'VZ 503', '93543773', 147, '$1974.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SRFP3500', 'Y', 'YR 162', '87898902', 274, '$1901.69');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZPXO2056', 'W', 'DM 930', '10174845', 181, '$2830.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UYCJ8148', 'Y', 'NA 077', '16103611', 239, '$2334.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TOOS1617', 'J', 'BX 202', '90988734', 58, '$283.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PCLP7523', 'W', 'WW 742', '20502716', 37, '$1666.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TAVL4391', 'Y', 'LI 985', '32127415', 289, '$2615.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JHJW9564', 'J', 'VV 600', '64765966', 215, '$891.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GEFK5676', 'J', 'EA 714', '96037462', 203, '$4431.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MEAI6579', 'J', 'XY 772', '24243157', 22, '$4828.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XBVM4523', 'Y', 'FT 589', '00130557', 44, '$4533.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QZIF3423', 'Y', 'HD 186', '52260834', 244, '$2429.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FPUY1183', 'W', 'CD 263', '81674784', 204, '$3729.00');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OYZC6606', 'J', 'VA 132', '57375637', 67, '$3243.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TVJY6237', 'W', 'VN 139', '62883796', 281, '$3314.77');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EJOE6011', 'J', 'MG 930', '57618852', 21, '$447.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EZWJ4494', 'W', 'VI 246', '77335529', 72, '$3923.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZFAA3284', 'W', 'EA 805', '87835257', 182, '$4244.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QXCV2450', 'J', 'UF 966', '17542571', 90, '$598.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IUFD7384', 'W', 'QO 997', '01293073', 38, '$297.99');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PDQO8367', 'Y', 'QF 239', '18226382', 121, '$3934.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KCHO1903', 'Y', 'HD 186', '71368887', 295, '$3314.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YRWH6608', 'W', 'TP 671', '69808473', 234, '$1834.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YLXA1634', 'Y', 'CR 563', '98257461', 73, '$1731.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WIRV4428', 'J', 'PO 705', '59829567', 3, '$3707.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SAET5332', 'Y', 'TV 344', '62764221', 30, '$2835.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QIKL5376', 'F', 'ST 180', '16456492', 82, '$4965.17');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MYIC9740', 'Y', 'MD 784', '88087511', 32, '$3019.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OGZH2127', 'J', 'SE 323', '30347601', 178, '$3148.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XOTE0608', 'W', 'TI 992', '08617294', 126, '$1578.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FMCB4878', 'J', 'CI 813', '62764221', 200, '$4691.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CLWR1582', 'Y', 'MF 795', '68807531', 232, '$2175.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KCDG3850', 'J', 'ZP 863', '85770297', 130, '$4424.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IRMP7893', 'Y', 'OC 854', '87898902', 173, '$953.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EEOX0537', 'F', 'ZP 458', '60051135', 297, '$3161.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VFOM4459', 'F', 'CR 563', '98845092', 291, '$3655.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JCVL9394', 'J', 'DE 053', '57280817', 5, '$2542.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QTWB9601', 'J', 'CI 813', '67493116', 187, '$2905.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WLLE2522', 'W', 'ST 147', '18226382', 99, '$541.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MOPE4674', 'W', 'ZE 184', '05949964', 60, '$247.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LWMO9170', 'W', 'QB 429', '27661857', 277, '$3221.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RDWR9184', 'J', 'ZJ 357', '28151554', 26, '$1135.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VSRV4560', 'J', 'NE 668', '85337194', 150, '$2643.78');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BSER1929', 'Y', 'CK 021', '20049535', 97, '$4413.69');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IALY3364', 'Y', 'FW 269', '81231428', 125, '$810.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GWCY9510', 'W', 'SJ 060', '16573625', 72, '$2421.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HICL9988', 'W', 'IJ 564', '00614964', 229, '$209.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YDIP8481', 'W', 'ZJ 357', '81314976', 134, '$4787.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JOPK9782', 'W', 'OL 737', '01293073', 6, '$3216.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZJQH9905', 'Y', 'VP 100', '54546886', 114, '$1476.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PEGJ2360', 'W', 'AH 272', '43851343', 111, '$618.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PCVP0083', 'W', 'AC 133', '69100259', 212, '$3896.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MNUF4872', 'W', 'XY 772', '87257749', 244, '$2411.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PTQJ3780', 'W', 'ST 180', '36046393', 72, '$1023.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GYPB0253', 'J', 'ZE 184', '07129158', 168, '$4581.03');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('THSY3158', 'J', 'IJ 564', '16346188', 81, '$799.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('URWX6371', 'W', 'SU 627', '80506782', 240, '$1829.86');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HVUP8257', 'W', 'NA 077', '19014083', 68, '$1066.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LSDZ0293', 'F', 'VV 600', '20161572', 183, '$836.79');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SJBF4273', 'W', 'MQ 793', '75953436', 98, '$4812.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XAPA2308', 'Y', 'BZ 794', '28492331', 79, '$515.33');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FJPE5842', 'J', 'ZO 430', '95975109', 188, '$243.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VFHF7495', 'W', 'VA 877', '50519849', 108, '$3746.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OOFS2374', 'J', 'QS 839', '14069840', 131, '$3334.49');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DNRI9723', 'J', 'UL 806', '74460311', 152, '$1464.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LHGQ2821', 'F', 'DT 673', '05396256', 201, '$400.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HFAK1435', 'Y', 'FT 215', '01373041', 113, '$1612.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UEBZ0861', 'J', 'PE 344', '47613873', 162, '$3883.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WKWF0122', 'Y', 'PI 359', '55423765', 150, '$2561.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IZUS1373', 'J', 'AT 362', '62143514', 239, '$853.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DSGB9614', 'J', 'QS 839', '13933332', 54, '$737.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CKKN7496', 'F', 'HE 072', '01977459', 137, '$3941.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ICHY1398', 'W', 'ZJ 357', '00130557', 12, '$4466.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FRQR0521', 'W', 'WF 431', '33527312', 27, '$2174.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DQWY0882', 'J', 'SJ 060', '91617761', 161, '$4882.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VXJN4742', 'J', 'YP 305', '49562547', 286, '$4586.09');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QLOZ5665', 'J', 'EN 334', '49159569', 216, '$1630.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UOAR4938', 'W', 'DF 740', '99551548', 142, '$280.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UKNC6207', 'J', 'YK 442', '63842193', 95, '$2001.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BSLN2363', 'W', 'LV 508', '23187054', 61, '$3469.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HOJD9864', 'Y', 'OL 737', '35254394', 31, '$1490.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YZKH0441', 'J', 'AH 272', '16752375', 76, '$164.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BKDU8386', 'J', 'OJ 008', '65505218', 223, '$3326.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YYCY4611', 'W', 'GV 164', '17056136', 135, '$2732.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ISXQ4649', 'F', 'CC 450', '33318683', 46, '$2223.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YMWH0514', 'W', 'TV 344', '80962217', 109, '$4881.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RBDW7316', 'J', 'TP 671', '36101432', 91, '$1109.77');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZBRC7681', 'J', 'GG 179', '69100259', 154, '$2801.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UMLQ1224', 'F', 'DE 995', '34982804', 257, '$4096.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VLEW7712', 'W', 'VA 877', '83380519', 193, '$1150.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TAUI1261', 'Y', 'QS 839', '88064742', 262, '$792.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DIWO9001', 'Y', 'QH 964', '47036692', 259, '$4878.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BOCG2438', 'J', 'QF 607', '72294479', 35, '$2179.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MLAS4555', 'Y', 'IJ 564', '19594779', 13, '$1352.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UHIR5853', 'W', 'MP 271', '24665394', 247, '$3994.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RDCI0409', 'W', 'XF 402', '19014083', 162, '$4477.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YUSE1955', 'J', 'CI 813', '24243157', 89, '$3964.25');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XBLK7778', 'W', 'MD 784', '22234337', 135, '$2919.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QGDI6938', 'J', 'JZ 483', '18169248', 143, '$1749.37');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MOBY8103', 'J', 'RG 468', '09860333', 56, '$698.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LQUU6771', 'W', 'QH 964', '67696349', 17, '$4654.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QXRL1772', 'F', 'WF 431', '57615741', 68, '$4093.49');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OWDC0420', 'J', 'CC 450', '01293073', 260, '$924.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DPND1464', 'Y', 'FZ 441', '64851539', 114, '$3760.26');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ESFH8482', 'F', 'KT 165', '05502162', 29, '$3533.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YPIS8714', 'W', 'ZG 279', '17815063', 228, '$3538.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KRSP7335', 'W', 'JR 712', '15324566', 268, '$1362.93');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BHSY8667', 'J', 'NS 842', '60606285', 156, '$808.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EMMM1769', 'W', 'FK 002', '26787626', 240, '$3707.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VWKK8961', 'W', 'GP 148', '55064095', 185, '$2227.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LMHX7057', 'Y', 'EA 805', '62761266', 149, '$1654.75');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MCTF0472', 'Y', 'QF 607', '67882602', 216, '$1348.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XNJY5580', 'J', 'GX 201', '28702515', 75, '$1400.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KEQF9858', 'Y', 'RS 632', '55367392', 111, '$4106.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QKWZ7794', 'W', 'NA 077', '62883796', 30, '$1611.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YUMM9039', 'Y', 'CC 450', '38240234', 201, '$346.37');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YYWJ2322', 'Y', 'DF 740', '50135398', 236, '$4440.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GAVO8055', 'J', 'YR 162', '21156781', 270, '$2498.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XDKQ7931', 'J', 'UL 806', '85857885', 172, '$2137.79');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EVXY8659', 'W', 'RJ 751', '02998601', 188, '$1367.67');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WYBR8388', 'J', 'TP 671', '15076148', 294, '$2023.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FSXY8319', 'Y', 'PJ 001', '22376000', 81, '$3898.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OGWL5705', 'F', 'WW 742', '36101432', 147, '$4199.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('POEP0398', 'J', 'MU 795', '92827922', 184, '$4028.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MAQZ0225', 'J', 'NS 674', '27332016', 116, '$3644.41');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KRDD9671', 'W', 'NS 674', '20391629', 94, '$2964.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SCWX0664', 'J', 'SU 627', '62764221', 273, '$2810.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NHIN1385', 'J', 'FQ 490', '19014083', 87, '$1137.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RARY2170', 'W', 'EI 901', '87498485', 140, '$840.35');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VQBH5528', 'W', 'XF 402', '21163258', 57, '$4639.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ESAW5028', 'Y', 'ML 770', '71368887', 88, '$3241.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LHAZ3816', 'J', 'DE 995', '99149331', 235, '$2230.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DRUH6901', 'W', 'OJ 008', '09685222', 1, '$2155.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OUUM0949', 'Y', 'PO 705', '91144158', 292, '$1646.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MVLI9913', 'Y', 'GX 201', '75960033', 295, '$3307.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YDUJ1877', 'J', 'GT 100', '90831040', 203, '$4228.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NGQG2683', 'Y', 'VH 352', '21047967', 145, '$4190.39');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EXFA6519', 'F', 'VV 600', '69073457', 162, '$4475.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QPXL6514', 'W', 'YR 162', '88707289', 16, '$3541.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MKHN3738', 'J', 'YS 207', '98845092', 134, '$3180.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PFYS8231', 'W', 'VL 928', '87615837', 254, '$1628.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MGZU1126', 'J', 'UD 378', '47889887', 255, '$3945.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RQUE9144', 'Y', 'YK 442', '56232616', 27, '$4440.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PHHO5929', 'Y', 'VB 885', '88828477', 297, '$1234.81');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DIDR5238', 'J', 'IF 068', '28318408', 116, '$2028.52');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZFNT8721', 'Y', 'GX 201', '36911132', 174, '$4183.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PSYY9592', 'Y', 'MH 757', '55367392', 118, '$4927.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VUDP9654', 'Y', 'AT 362', '06058572', 68, '$4862.41');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SWTG5796', 'Y', 'DM 930', '17506861', 300, '$3035.79');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KRXZ2913', 'F', 'RA 632', '05475100', 176, '$228.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LPYS0622', 'W', 'IX 315', '54496894', 233, '$1364.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BXAZ9723', 'J', 'YK 442', '15902113', 234, '$3786.13');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CZPB0104', 'W', 'CU 286', '17542571', 38, '$2123.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ISXY5201', 'Y', 'RX 159', '53054109', 3, '$1789.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ERUX3763', 'Y', 'MP 271', '16531754', 61, '$1373.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GBXS5314', 'W', 'NQ 204', '04858972', 46, '$2899.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TMLF8662', 'J', 'UF 497', '04679087', 213, '$2080.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JORM6460', 'Y', 'AH 272', '46608208', 297, '$779.81');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZQWW8701', 'W', 'ND 911', '26010133', 223, '$236.47');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SNHP3433', 'Y', 'RS 632', '07129158', 247, '$2880.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZCBA8471', 'W', 'ZO 430', '59829567', 282, '$2215.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GHIZ1073', 'J', 'VH 352', '92039250', 13, '$3662.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SOMM7277', 'J', 'CD 263', '56232616', 261, '$1242.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CSMA7654', 'J', 'GZ 512', '15076148', 5, '$3513.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZCVT9034', 'J', 'YR 162', '16346188', 180, '$3895.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QZZD0543', 'Y', 'ML 770', '67253718', 297, '$2823.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DQHY9653', 'W', 'ZP 458', '08391580', 279, '$4763.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NNIS8342', 'W', 'IO 348', '42523517', 72, '$464.17');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PTHO0674', 'F', 'SE 323', '67415180', 31, '$2462.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UPZZ7778', 'Y', 'VI 246', '68212839', 133, '$1886.83');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CCYD5075', 'F', 'FK 002', '90787904', 267, '$4706.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FNCA3317', 'W', 'VV 600', '25535597', 57, '$3777.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UQLC2701', 'W', 'PJ 001', '85770297', 56, '$779.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SKCB3767', 'W', 'SH 048', '87766736', 295, '$4460.69');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FTTO3960', 'J', 'NA 077', '88828477', 109, '$1345.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JSTM6767', 'W', 'ZE 184', '04679087', 80, '$1069.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DYMV2903', 'W', 'KH 340', '61300575', 117, '$1066.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QMJO1307', 'J', 'MD 784', '61488272', 129, '$4736.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CJZH0120', 'F', 'BL 389', '69808473', 16, '$2032.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UIFW6203', 'F', 'QF 474', '07854851', 132, '$4851.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WNTB3368', 'J', 'YX 198', '14930507', 245, '$1080.54');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZDDA3481', 'J', 'PJ 001', '29440514', 298, '$4686.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HJOZ1444', 'F', 'LP 806', '81674784', 143, '$1282.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VOTQ3759', 'W', 'XY 772', '17542571', 271, '$1896.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PDWP8934', 'F', 'FQ 490', '69100259', 282, '$1735.97');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EPMC2699', 'W', 'TV 344', '35690416', 8, '$4300.79');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IFES6017', 'W', 'UF 966', '59091091', 116, '$1185.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RTFB9770', 'Y', 'IA 834', '05502162', 50, '$4304.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HDVS5614', 'J', 'FZ 441', '15902113', 85, '$912.34');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QRIH8897', 'F', 'CR 563', '29967804', 1, '$4415.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZMLB0819', 'J', 'AN 989', '15095037', 169, '$992.15');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TEHZ8547', 'Y', 'ZE 184', '70272289', 115, '$2794.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NTKC3216', 'Y', 'FT 215', '53054109', 257, '$3261.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OHVN2426', 'W', 'NS 842', '35521126', 179, '$99.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OKBI5472', 'Y', 'FZ 441', '89461258', 95, '$392.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SIQH5015', 'Y', 'MF 795', '59201145', 60, '$1861.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XKKS0210', 'Y', 'FT 589', '17443686', 109, '$1315.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LQRQ4324', 'W', 'VR 146', '33744759', 270, '$128.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EVVC0613', 'Y', 'XL 786', '71210252', 207, '$4262.52');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IYVV1287', 'J', 'KG 314', '15076148', 24, '$3247.65');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KWYC2267', 'J', 'CS 285', '72418778', 286, '$2288.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RZRF1049', 'Y', 'VZ 503', '74869186', 151, '$3524.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IATC3247', 'W', 'ML 770', '59829567', 201, '$2158.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EDQY5231', 'W', 'NA 077', '67273520', 300, '$2884.76');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SJEG2421', 'W', 'YX 198', '90988734', 77, '$1878.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ASNC0715', 'J', 'EA 805', '75645929', 244, '$3840.80');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UHOR1149', 'Y', 'UL 806', '77379402', 300, '$3902.77');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FWAS4054', 'J', 'ZP 863', '83191185', 9, '$3926.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LPFP5453', 'F', 'NA 077', '70272289', 113, '$1359.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LRML2561', 'Y', 'PJ 647', '45925652', 113, '$2120.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IBBD8808', 'W', 'FM 573', '42416206', 116, '$3090.95');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XPDZ1219', 'W', 'YR 162', '36260630', 65, '$4505.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KISH7758', 'J', 'ND 911', '67999316', 121, '$379.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UBCS6080', 'J', 'LZ 930', '92077884', 176, '$3685.13');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IYKO7692', 'J', 'PJ 001', '93543773', 14, '$2157.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZLIR9345', 'J', 'BZ 794', '35521126', 173, '$481.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VISK4335', 'J', 'ZL 530', '28151554', 192, '$4403.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MPZV6497', 'W', 'MG 930', '73758764', 145, '$165.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TXQE1069', 'F', 'SH 048', '24456745', 74, '$4696.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HCMX4247', 'J', 'BC 789', '08986110', 12, '$3399.97');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UXIQ5472', 'Y', 'OJ 008', '81958720', 79, '$3903.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XOVA3145', 'Y', 'GZ 512', '22170126', 154, '$497.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MISX6911', 'W', 'NQ 204', '88261127', 249, '$229.80');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RHXZ5799', 'W', 'IJ 564', '72230777', 212, '$4366.43');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RQSB6228', 'W', 'LZ 930', '94830505', 86, '$4455.74');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WWEG6577', 'J', 'BZ 794', '88660704', 169, '$3704.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PFJY4827', 'Y', 'VB 795', '51757291', 282, '$2332.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OUUJ5366', 'Y', 'VB 795', '61699687', 200, '$4512.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HMCT2212', 'J', 'YP 305', '05396895', 35, '$1398.06');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZHBJ8831', 'W', 'GP 148', '80935436', 81, '$3390.53');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KBHH6146', 'W', 'VA 132', '27332016', 234, '$4795.84');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CGTO9085', 'J', 'GV 052', '18226382', 8, '$4366.60');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TWBS9725', 'W', 'QB 429', '58195887', 96, '$4926.33');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LUSO1941', 'J', 'YK 442', '06058572', 275, '$3286.39');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KTAB9617', 'J', 'DT 673', '18282997', 127, '$4414.13');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JWTI1955', 'J', 'LT 512', '79652274', 117, '$1058.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FDNM6745', 'W', 'JD 706', '30477187', 152, '$4704.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SYIL1038', 'W', 'LX 199', '44828717', 169, '$4939.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WYAN9325', 'J', 'YX 198', '67493116', 199, '$925.49');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JAMC5713', 'J', 'FH 258', '99551548', 74, '$724.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NDUM9815', 'F', 'UZ 409', '48958287', 75, '$2348.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZATM9996', 'W', 'UD 378', '48958287', 118, '$458.46');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FBMQ8642', 'J', 'GZ 512', '08184228', 265, '$3573.99');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XFEP5415', 'Y', 'FR 949', '19761714', 239, '$2737.14');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('APPT0275', 'J', 'UD 378', '20161572', 49, '$313.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FTMX3433', 'J', 'QZ 396', '78518151', 12, '$4319.03');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BUBS3178', 'Y', 'QB 429', '08669987', 255, '$276.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XDXW1786', 'Y', 'ZJ 357', '17443686', 96, '$1398.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EOFX4596', 'Y', 'LZ 930', '05076247', 190, '$218.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AISD5246', 'Y', 'CJ 329', '58104633', 178, '$3843.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WXUG4967', 'Y', 'LX 199', '90431741', 77, '$3078.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KPEO9470', 'Y', 'MD 784', '91947888', 39, '$4846.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NHGO4044', 'J', 'VV 600', '17443686', 33, '$3433.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CYSL9337', 'Y', 'US 277', '48215948', 20, '$2114.91');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WZVJ1911', 'Y', 'ZE 184', '57280817', 282, '$1224.71');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NCWW9534', 'W', 'TI 992', '22610247', 257, '$2479.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WYCX2106', 'Y', 'GE 692', '90431741', 162, '$1483.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JYZN0747', 'J', 'DY 653', '90317087', 73, '$4314.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PNQQ9054', 'W', 'ZO 430', '50135398', 261, '$442.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QVNC8605', 'Y', 'JR 712', '06062676', 81, '$993.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IXTY8064', 'W', 'MH 757', '15139654', 165, '$558.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BRIZ1314', 'J', 'ND 911', '89445564', 149, '$3470.10');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HENT9756', 'Y', 'VV 600', '81958720', 107, '$3126.78');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LHWP2389', 'J', 'JR 712', '59201145', 92, '$4858.63');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YQHI4935', 'W', 'RS 632', '75960033', 288, '$3500.07');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZZVX8734', 'Y', 'ZE 184', '82704385', 229, '$3826.64');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GSLJ1508', 'J', 'FM 573', '18169248', 72, '$4308.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZZHF5503', 'J', 'DE 995', '96240176', 201, '$2233.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PLBE2697', 'W', 'GE 692', '08391580', 242, '$1224.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UPDG1010', 'W', 'LU 202', '84707385', 50, '$4077.65');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GAQI9253', 'W', 'NS 674', '56886025', 64, '$4818.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EQOZ1963', 'Y', 'GV 052', '98257461', 91, '$3877.47');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('META8592', 'Y', 'LP 806', '00130557', 226, '$4819.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BRMP7181', 'J', 'OT 330', '74946433', 168, '$88.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MWZO7726', 'W', 'PK 064', '91617761', 168, '$2005.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CZDK8340', 'W', 'CD 263', '87257749', 183, '$2819.62');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XQSB9095', 'J', 'EA 805', '60051135', 253, '$3194.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MLTW2095', 'Y', 'FT 589', '73758764', 87, '$2741.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HOAU5722', 'J', 'VB 795', '19580154', 11, '$2219.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JQNI9850', 'Y', 'YS 207', '99675600', 111, '$2227.82');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VIWL1123', 'Y', 'DM 930', '68554816', 180, '$3819.48');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VXWQ1174', 'W', 'YK 442', '87498485', 185, '$3793.98');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YFHA2740', 'J', 'DF 740', '89445564', 96, '$4024.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('WQRY6458', 'Y', 'SH 048', '60051135', 143, '$2572.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FZUI7553', 'J', 'HE 072', '90999927', 99, '$4817.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LQPY1245', 'J', 'OB 839', '85337194', 264, '$2671.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FDRO0573', 'W', 'XL 786', '64064793', 55, '$4976.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IRGM1401', 'Y', 'CI 813', '77379402', 104, '$753.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LKVK5901', 'W', 'FH 258', '15250752', 285, '$2580.29');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YWLJ1984', 'W', 'JZ 483', '88707289', 227, '$3340.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UPEV9886', 'Y', 'LX 199', '75689282', 116, '$1870.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BVWG8515', 'Y', 'FT 215', '62143514', 19, '$3496.89');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CABW7431', 'Y', 'FW 269', '41013275', 121, '$1212.44');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YHWD7747', 'Y', 'JD 706', '60051135', 242, '$1421.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NTKZ0851', 'W', 'CM 255', '82122385', 201, '$1422.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CGHN8897', 'J', 'QF 239', '90994110', 77, '$4321.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JGNX5079', 'W', 'KT 165', '70272289', 74, '$2471.28');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DYWG1989', 'J', 'YF 362', '97627792', 163, '$4898.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IYCV8881', 'J', 'UX 023', '26677987', 215, '$4233.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PHNH5232', 'J', 'IG 452', '98448395', 88, '$816.66');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GPVV0172', 'Y', 'GT 100', '35521126', 56, '$1855.94');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JPYF1284', 'W', 'IO 348', '05076247', 251, '$2456.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MBTT8230', 'J', 'XL 786', '52287025', 131, '$3148.70');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BRZO1634', 'J', 'VR 146', '56232616', 111, '$4917.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XBYD4252', 'W', 'CU 286', '59991562', 170, '$3033.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EQUX0788', 'W', 'MU 795', '25142090', 60, '$1676.96');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UIUR0503', 'J', 'QZ 396', '90431741', 219, '$4530.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FXIH4151', 'J', 'IG 452', '36046393', 278, '$907.73');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LBMC6137', 'W', 'FR 949', '19315538', 50, '$1758.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EMUR0037', 'J', 'WE 064', '85967836', 86, '$4771.22');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NMWZ5468', 'Y', 'PJ 647', '55881706', 132, '$1756.31');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PEBJ6276', 'W', 'XF 119', '97772063', 215, '$4049.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QSVB4996', 'W', 'MF 795', '94386793', 134, '$1803.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BEQO8574', 'Y', 'XF 402', '20049535', 35, '$3987.59');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SUJW6099', 'Y', 'NE 668', '22398445', 229, '$1102.78');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EVVB9130', 'Y', 'DY 653', '81477356', 26, '$2656.92');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RWCL5257', 'Y', 'LI 985', '88828477', 47, '$3062.45');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BPIQ8203', 'J', 'YK 442', '00614964', 230, '$3191.61');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('EBDZ0142', 'J', 'DE 995', '00438831', 293, '$687.84');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QVOP6293', 'Y', 'QO 997', '54324904', 235, '$1349.32');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('TLFE3202', 'Y', 'VL 928', '54309694', 248, '$330.80');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('RMYH4745', 'Y', 'KV 831', '33744759', 291, '$2842.87');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OTQN7018', 'W', 'NS 674', '89096598', 168, '$1297.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('NFLF0452', 'J', 'VB 795', '64851539', 167, '$2159.05');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SAMF4317', 'J', 'EA 805', '48948937', 141, '$4392.33');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CFVQ5233', 'Y', 'GW 845', '04356983', 105, '$1129.27');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('SBSB3127', 'Y', 'VA 877', '33318683', 112, '$1277.21');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DLYW9369', 'W', 'CJ 329', '75960033', 146, '$819.84');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('AUYV4305', 'Y', 'EA 805', '17443686', 41, '$2862.36');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XAVP1451', 'J', 'MH 757', '79177322', 292, '$3019.01');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('UEIS9927', 'W', 'PE 344', '95517222', 56, '$2622.68');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('VVYO4763', 'W', 'ZJ 357', '41013275', 211, '$777.88');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('LANO8563', 'Y', 'WF 431', '59428683', 123, '$1337.51');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('IWCB2074', 'Y', 'IA 834', '93543773', 78, '$1272.38');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XZDS4068', 'W', 'EI 901', '62143514', 37, '$1557.18');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('CLVH0876', 'Y', 'VH 352', '62143514', 287, '$3008.12');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ZIMP7345', 'W', 'YK 442', '30347601', 226, '$3923.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GJRT0986', 'J', 'FK 002', '75750998', 96, '$351.40');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('ISGK1014', 'W', 'KH 340', '99675600', 217, '$2903.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JKQK7742', 'W', 'MD 109', '29790005', 185, '$4778.79');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('GVPA8627', 'Y', 'LX 199', '00438831', 279, '$4544.02');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DQEZ0987', 'F', 'JK 999', '92612348', 11, '$3346.50');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('XVOJ0058', 'Y', 'SJ 060', '53455827', 102, '$4736.47');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('PIST9959', 'W', 'PO 705', '93795457', 227, '$3235.23');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('KZUC0099', 'J', 'JD 706', '86182227', 124, '$925.55');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HUIK5498', 'W', 'ZG 279', '30797850', 42, '$1637.42');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OSTF4923', 'Y', 'IJ 564', '26010133', 28, '$253.69');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JEDY0528', 'W', 'JD 706', '02704470', 229, '$901.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JGEO5540', 'Y', 'IH 336', '93543773', 100, '$1508.19');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HHBV5875', 'F', 'WE 064', '15902113', 67, '$3162.11');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('MRMU5772', 'Y', 'IX 315', '92827922', 291, '$530.41');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('QAXW0212', 'Y', 'TP 671', '95975109', 126, '$1902.17');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('FFDK0488', 'Y', 'WI 057', '57280817', 96, '$4991.58');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BGGN6290', 'J', 'ST 147', '16466095', 179, '$1709.72');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YQQT1718', 'W', 'NR 260', '11057658', 26, '$3036.85');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('HWNW2366', 'Y', 'YF 362', '68554816', 86, '$799.57');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('JZKG1997', 'Y', 'RJ 751', '95975109', 64, '$3160.30');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('BTAW6366', 'J', 'YF 362', '81231428', 183, '$399.20');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('DCEP3170', 'J', 'VX 674', '62761266', 72, '$1420.90');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('YPQZ2086', 'F', 'SW 408', '09685222', 273, '$4344.24');
insert into VE (MAVE, MAHV, MACB, MAHD, GHE, GIAVE) values ('OHEE7518', 'W', 'QF 607', '51472095', 175, '$2944.92');
GO

--> PROCEDURE <--
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
EXEC PRC_TongTienDaMua @MAKH = 'KH002015', @TONGTIENDATHANHTOAN = @tongtien OUTPUT
PRINT @tongtien
GO
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
    IF NOT EXISTS (SELECT 1 FROM HOADON WHERE MAHD = @MAHD)
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

--> FUNCTION <--
CREATE FUNCTION DEM_SLKHDK_THEOTHANG (
    @p_month INT,
    @p_year INT
)
RETURNS INT
BEGIN
    DECLARE @SLKH INT;
    SELECT @SLKH = COUNT(*)
    FROM KHACHHANG
    WHERE MONTH(NGAYTAOTK) = @p_month AND YEAR(NGAYTAOTK) = @p_year;
    RETURN @SLKH;
END;
GO

CREATE FUNCTION DEM_SLCB_THEOTHANG (
	@p_month INT,
	@p_year INT
)
RETURNS INT
BEGIN
	DECLARE @SLCB INT;
	SELECT @SLCB = COUNT(*)
	FROM CHUYENBAY
	WHERE MONTH(NGAYKHOIHANH) = @p_month AND YEAR(NGAYKHOIHANH) = @p_year;
	RETURN @SLCB;
END;
GO

CREATE FUNCTION DOANHTHU (
	@p_day INT,
	@p_month INT,
	@p_year INT
)
RETURNS DECIMAL(10,2)
BEGIN 
	DECLARE @DOANHTHU DECIMAL(10,2);
	IF (@p_day IS NOT NULL AND @p_month IS NULL) OR
		(@p_month IS NOT NULL AND @p_year IS NULL)
	BEGIN
		SET @DOANHTHU = NULL;
		RETURN @DOANHTHU;
	END
	
	IF (@p_day IS NOT NULL) 
	BEGIN
		SELECT @DOANHTHU = COALESCE(SUM(HD.THANHTIEN), 0)
		FROM HOADON HD
		WHERE DAY(HD.NGAYLAP) = @p_day
			AND MONTH(HD.NGAYLAP) = @p_month
			AND YEAR(HD.NGAYLAP) = @p_year
			AND TINHTRANG = 1;
	END
	ELSE
		IF (@p_month IS NOT NULL) 
		BEGIN
			SELECT @DOANHTHU = COALESCE(SUM(HD.THANHTIEN), 0)
			FROM HOADON HD
			WHERE MONTH(HD.NGAYLAP) = @p_month
				AND YEAR(HD.NGAYLAP) = @p_year
				AND TINHTRANG = 1;
		END
		ELSE
			IF (@p_year IS NOT NULL) 
			BEGIN
				SELECT @DOANHTHU = COALESCE(SUM(HD.THANHTIEN), 0)
				FROM HOADON HD
				WHERE YEAR(HD.THANHTIEN) = @p_year
					AND TINHTRANG = 1;
			END
		
	RETURN @DOANHTHU;
END
GO
