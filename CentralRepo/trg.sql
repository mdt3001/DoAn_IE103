--Kiểm tra số ghế thường và số ghế vip còn lại
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


--Trigger kiểm tra độ tuổi của nhân viên ( lớn hơn 18 )
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


--Trigger tạo mã tuyến bay
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


--Trigger tính giờ hạ cánh của chuyến 
CREATE TRIGGER TRG_GIOHACANH ON CHUYENBAY
AFTER INSERT AS
BEGIN
    UPDATE CHUYENBAY
    SET GIOHACANH = CAST(DATEADD(MINUTE, DATEDIFF(MINUTE, 0, CAST(I.THOIGIANDUKIEN AS DATETIME)), CAST(C.GIOKHOIHANH AS DATETIME)) AS TIME)
    FROM CHUYENBAY C
    INNER JOIN inserted I ON C.MACB = I.MACB;
END


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

    
-- Trigger kiểm tra tính hợp lệ của ghế
CREATE TRIGGER TRG_THEMVE ON VE
INSTEAD OF INSERT AS
BEGIN
    DECLARE @tongghevip INT, @tongghethuong INT, @mahv CHAR(8), @ghe CHAR(3), @macb CHAR(8);
    DECLARE cur CURSOR FOR SELECT MAHV, GHE, MACB FROM inserted;
	OPEN cur;
    FETCH NEXT FROM cur INTO @mahv, @ghe, @macb;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SELECT @tongghevip = SOGHEVIP, @tongghethuong = SOGHETHUONG FROM MAYBAY
        JOIN CHUYENBAY ON MAYBAY.MAMB = CHUYENBAY.MAMB
        WHERE CHUYENBAY.MACB = @macb;
        --Kiểm tra tính hợp lý của ghế vip
        IF @mahv = 'F' AND (SELECT SOGHEHANGVIPCONLAI FROM CHUYENBAY WHERE MACB = @macb) > 0 AND @ghe > 0 AND @ghe <= @tongghevip
        BEGIN
            UPDATE CHUYENBAY
            SET SOGHEHANGVIPCONLAI = SOGHEHANGVIPCONLAI - 1
            WHERE MACB = @macb;
            INSERT INTO VE SELECT * FROM inserted WHERE MACB = @macb AND MAHV = @mahv AND GHE = @ghe;
        END
        --Kiểm tra tính hợp lệ của ghế thường
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
    CLOSE cur;
    DEALLOCATE cur;
END;
