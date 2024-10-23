-- drop table IF EXISTS  Participants, Feedback, Matches, Clients, Meetings;

-- Vytvoøení tabulek a dat

CREATE TABLE Clients
(
    client_id  INT Identity(1,1) PRIMARY KEY,
    name       NVARCHAR(150) NOT NULL,
    email      NVARCHAR(150) NOT NULL,
    phone      NVARCHAR(150) NOT NULL,
    categories NVARCHAR(MAX)
);

INSERT INTO Clients (name, email, phone, categories)
VALUES 
	('client_1', 'client_1@example.com', '123 456 789', '["Category A", "Category B"]'),
    ('client_2', 'client_2@example.com', '123 456 789', '["Category B", "Category C"]'),
    ('client_3', 'client_3@example.com', '123456789', '["Category C", "Category A"]'),
    ('client_4', 'client_4@example.com', '123456789', '["Category A", "Category B", "Category C"]');

-- SELECT * FROM Clients;

-- -----

CREATE TABLE Meetings
(
    meeting_id INT Identity(1,1) PRIMARY KEY,
    theme      NVARCHAR(200),
    date       DATE,
    categories NVARCHAR(MAX)
);

INSERT INTO Meetings (theme, date, categories)
VALUES
	('Téma 1', '2024-09-01', '["Category A"]'),
	('Téma 2', '2024-09-07', '["Category B"]'),
	('Téma 3', '2024-09-14', '["Category C"]'),
	('Téma 4', '2024-09-21', '["Category C", "Category A"]');

-- SELECT * FROM Meetings;

-- -----

CREATE TABLE Participants
(
    meeting_id INT,
    client_id  INT,
    PRIMARY KEY (meeting_id, client_id),
    FOREIGN KEY (meeting_id) REFERENCES Meetings (meeting_id),
    FOREIGN KEY (client_id) REFERENCES Clients (client_id)
);

INSERT INTO Participants (meeting_id, client_id)
SELECT m.meeting_id, c.client_id
FROM Clients AS c
JOIN Meetings AS m
    ON EXISTS (
		SELECT 1 FROM OPENJSON(c.categories) 
		WHERE VALUE IN (SELECT VALUE FROM OPENJSON(m.categories)));

-- SELECT * FROM Participants ORDER BY meeting_id;

-- -----

CREATE TABLE Feedback
(
	feedback_id    INT IDENTITY (1,1) PRIMARY KEY,
	meeting_id     INT,
	client_from_id INT,
	client_to_id   INT,
	rating         NVARCHAR(50) CHECK (rating IN ('positive', 'negative')),
	comments       NVARCHAR(MAX),
	FOREIGN KEY (meeting_id) REFERENCES Meetings (meeting_id),
	FOREIGN KEY (client_from_id) REFERENCES Clients (client_id),
	FOREIGN KEY (client_to_id) REFERENCES Clients (client_id)
);

-- TRUNCATE TABLE Feedback;

INSERT INTO Feedback (meeting_id, client_from_id, client_to_id)
SELECT p1.meeting_id,
       p1.client_id as client_from_id,
       p2.client_id as client_to_id
FROM Participants p1
JOIN Participants p2 
	on p1.meeting_id = p2.meeting_id
WHERE p1.client_id != p2.client_id;

UPDATE f
SET f.rating   = i.rating,
    f.comments = i.comments
FROM Feedback AS f 
JOIN (VALUES 
	(1, 'negative', 'abc'),
    (2, 'positive', 'abc'),
    (3, 'negative', 'abc'),
    (4, 'positive', 'abc'),
    (5, 'negative', 'abc'),
    (6, 'positive', 'abc'),
    (7, 'positive', 'abc'),
    (8, 'positive', 'abc'),
    (9, 'positive', 'abc'),
    (10, 'positive', 'abc'),
    (11, 'positive', 'abc'),
    (12, 'positive', 'abc'),
    (13, 'positive', 'abc'),
    (14, 'positive', 'abc'),
    (15, 'positive', 'abc'),
    (16, 'positive', 'abc'),
    (17, 'negative', 'abc'),
    (18, 'positive', 'abc'),
    (19, 'negative', 'abc'),
    (20, 'positive', 'abc'),
	(21, 'positive', 'abc'),
    (22, 'negative', 'abc'),
    (23, 'negative', 'abc'),
    (24, 'positive', 'abc'),
    (25, 'positive', 'abc'),
    (26, 'positive', 'abc'),
    (27, 'negative', 'abc'),
    (28, 'positive', 'abc'),
    (29, 'positive', 'abc'),
    (30, 'negative', 'abc')
    ) AS i (feedback_id, rating, comments)
ON f.feedback_id = i.feedback_id;

/*
select*
FROM Feedback
-- WHERE rating = 'positive'
order by meeting_id, client_from_id;
*/
-- -----

CREATE TABLE Matches
(
    client_name  nvarchar(150),
    client_email nvarchar(150),
    client_phone nvarchar(150),
    match_name   nvarchar(150),
    match_email  nvarchar(150),
    match_phone  nvarchar(150),
    meeting_id   INT
);

-- ---------

-- Procedura k tvorbì reportu:
-- Pøehled pozitivních shod klientù a pøehled kontaktních informací.

IF OBJECT_ID('generate_match', 'P') IS NOT NULL
    DROP PROCEDURE generate_match;
GO
CREATE PROCEDURE generate_match (@generated_meeting_id INT)
AS
BEGIN
    TRUNCATE TABLE Matches;

    INSERT INTO Matches
    SELECT c1.name  as client_name,
           c1.email as client_email,
           c1.phone as client_phone,
           c2.name  as match_name,
           c2.email as match_email,
           c2.phone as match_phone,
           f1.meeting_id
    FROM Feedback AS f1
    JOIN Feedback AS f2 
		ON f1.meeting_id = f2.meeting_id
		 AND f1.client_from_id = f2.client_to_id
		 AND f1.client_to_id = f2.client_from_id
    JOIN Clients AS c1 ON f1.client_from_id = c1.client_id
    JOIN Clients AS c2 ON f1.client_to_id = c2.client_id
    WHERE 1=1
		AND f1.rating = 'positive'
		AND f2.rating = 'positive'
		AND f1.meeting_id = @generated_meeting_id;

    SELECT * FROM Matches;
END;
GO

-- ---------

-- pro report zadat meeting_id  1 - 4


EXEC generate_match 4;


EXEC generate_match 1;

EXEC generate_match 2;

EXEC generate_match 3;
