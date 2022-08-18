-- Procedura wyswiatla ile pracownik o podanym imieniu realizowal zamowien
CREATE PROCEDURE whoSoldTheMost
@name varchar(20)
AS
IF EXISTS(SELECT(1) FROM OSOBA O WHERE O.IMIE = @name)
	BEGIN
		DECLARE @SUM INT;
		SELECT @SUM = (select count(*)
		from zamowienie z JOIN pracownik p ON z.pracownik_id_osoba_pracownik = p.id_osoba_pracownik JOIN OSOBA o ON p.id_osoba_pracownik = o.id_osoba
		WHERE O.IMIE = @name)
		IF(@SUM > 0)
			BEGIN
				PRINT 'Pracownik ' + @name + ' realizowal ' + CAST(@SUM AS VARCHAR(20)) + ' zamowien/zamowienia'
			END
		ELSE
			BEGIN
				PRINT 'Pracownik ' + @name + ' nie zrealizowal zadnego zamowienia'
			END
	END
ELSE
	BEGIN
		PRINT 'Pracownik o podanym imieniu nie istnieje'
	END




-- Procedura zmienia pensje pracownikow odpowiednio do padonej liczby
CREATE PROCEDURE increaseSalary
@percent FLOAT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE increasing CURSOR
	FOR SELECT ID_OSOBA_PRACOWNIK, PENSJA FROM PRACOWNIK
	DECLARE @SAL INT, @id_osoba INT;
	OPEN increasing 
	fetch next from increasing into @id_osoba, @SAL
	WHILE @@FETCH_STATUS=0
	BEGIN 
		UPDATE PRACOWNIK
		SET PENSJA = PENSJA * @percent
		where @id_osoba = ID_OSOBA_PRACOWNIK
		IF(@percent > 1.0)
		BEGIN
			PRINT  'Wyplata dla pracownika ' + CAST(@id_osoba AS VARCHAR) + ' zostala podwyzszona do ' + CAST(@sal * @percent AS VARCHAR);
		END
		ELSE
		BEGIN
			PRINT 'Wyplata dla pracownika ' + CAST(@id_osoba AS VARCHAR) + ' zostala obnizona do ' + CAST(@sal * @percent AS VARCHAR);
		END
		fetch next from increasing into @id_osoba, @SAL
	END
	CLOSE increasing
	DEALLOCATE increasing
END





-- Funkcja przyjmuje nazwe produktu i zwraca ile razy produkt byl sprzedawany
CREATE FUNCTION FN_getQuantity(@produkt VARCHAR(20))
RETURNS VARCHAR(50)
AS
BEGIN
DECLARE @RESULT VARCHAR(50);
IF EXISTS(SELECT (1) FROM PRODUKT P WHERE P.NAZWA = @produkt)
	BEGIN
	DECLARE @SUM INT;
		SELECT @SUM = (select count(*)
		from PRODUKT P JOIN ZAMOWIENIE_PRODUKT Z ON P.ID_PRODUKT = Z.PRODUKT_ID_PRODUKT
		WHERE P.NAZWA = @produkt)
		IF(@SUM > 0)
			BEGIN
				SELECT @RESULT = 'Produkt : ' + @produkt + ' byl sprzedawany ' + CAST(@SUM AS VARCHAR(20)) + ' razy'
			END
		ELSE
			BEGIN
				SELECT @RESULT = 'Produkt nigny nie byl sprzedawany'
			END
	END
ELSE
	BEGIN
		SELECT @RESULT = 'Produkt o podanej nazwie nie istnieje'
	END
RETURN @RESULT
END



--Wyzwalacz nie pozwala obnizac pensje pracownikom i dodawac nowych pracownikow z pensja 0
CREATE TRIGGER trig_pracownik ON pracownik
AFTER INSERT, UPDATE
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted)
	BEGIN
		IF(SELECT PENSJA FROM inserted) < (SELECT PENSJA FROM deleted)
		BEGIN
			RAISERROR ('Nie mozna zmieniac pensje pracowniaka na mniejsza', 15, 1)
			ROLLBACK;
		END
	END
	IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
	BEGIN
		DECLARE @SUM INT
		SELECT @SUM = PENSJA FROM inserted;
		IF(@SUM = 0)
		BEGIN 
			RAISERROR ('Pensja nowego pracownika nie moze byc 0', 15, 1)
			ROLLBACK;
		END;
	END

END;


--wyzwalacz nie pozwala zmieniac nazwisk zarejestrowanych osob, rejestrowac nowych osob o juz stworzonym nazwisku i usuwac juz zarejestrowanych osob
CREATE TRIGGER trig_osoba ON osoba
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
	BEGIN
		IF(SELECT NAZWISKO FROM inserted) <> (SELECT NAZWISKO FROM deleted)
		BEGIN
			RAISERROR ('Nie mozna zmieniac nazwiska osob', 15, 1)
			ROLLBACK;
		END
	END
	IF EXISTS (SELECT * FROM inserted) AND NOT EXISTS(SELECT * FROM deleted)
	BEGIN
		IF EXISTS(SELECT * FROM OSOBA O WHERE O.NAZWISKO = (SELECT NAZWISKO FROM inserted))
		BEGIN
			RAISERROR ('Osoba o takim nazwiskiem juz jest zarejestrowana', 15, 1)
			ROLLBACK;
		END
	END
	IF EXISTS (SELECT * FROM deleted) AND NOT EXISTS(SELECT * FROM inserted)
	BEGIN
		RAISERROR ('Nie ma mozliwosci usuniecia zarejestrowanych osob', 15, 1)
		ROLLBACK;
	END
END
