
--Kiem tra ve thuong va ve vip
CREATE OR ALTER TRIGGER Trg_CheckSeatAvailability
ON CHUYENBAY
FOR INSERT
AS
BEGIN
    DECLARE @SogheThuong INT, @SogheVip INT;
    SELECT @SogheThuong = MAYBAY.SOGHETHUONG, @SogheVip = MAYBAY.SOGHEVIP
    FROM INSERTED
    INNER JOIN MAYBAY ON INSERTED.MAMB = MAYBAY.MAMB;

    IF EXISTS (SELECT 1 FROM INSERTED WHERE INSERTED.SOGHEHANGTHUONGCONLAI > @SogheThuong OR INSERTED.SOGHEHANGVIPCONLAI > @SogheVip)
    BEGIN
        RAISERROR ('Số lượng ghế vượt quá số lượng ghế của máy bay.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;


--Kiem tra tuoi nhan vien lon hon 18
GO

CREATE TRIGGER KiemTraTuoiNhanVien
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


--Tao matb
CREATE TRIGGER TRG_AUTO_GENERATE_MATB
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

insert into TUYENBAY (MASBDI, MASBDEN) VALUES ('TRG', 'TUA');