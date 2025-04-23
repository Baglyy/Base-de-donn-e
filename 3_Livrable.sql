-- Requête 1 : Afficher le nom des compteurs ayant des FORTE probabilités d'anomalie Hors vacances
-- (utilisation de JOIN)

SELECT DISTINCT C.libelle
FROM Compteur C
JOIN nbVelos V ON C.idCpt = V.idCpt
JOIN Date D ON D.date = V.date
WHERE V.probAnomalie = 'FORTE'
    AND D.vacances = 'HORS VACANCES';

/* 40 tuples : 
    Pont Willy Brandt vers Malakoff
    Stalingrad vers ouest
    Pont Tabarly vers Nord
    Philippot vers Est
    Calvaire vers Est
    ...
*/

-- ---------------------------------------------------------------------------------------------------------

-- Requête 2 : Afficher l'identifiant des quartiers ayant plusieurs compteurs
-- (utilisation de JOIN)

SELECT DISTINCT C1.idQ
FROM Compteur C1
JOIN Compteur C2 ON C1.idQ = C2.idQ AND C1.idCpt < C2.idCpt;

/* 9 tuples :
    1
    4
    5
    6
    8 
    ...
*/

-- ---------------------------------------------------------------------------------------------------------

-- Requête 3 : Afficher le nombre de compteurs dans chaque quartier
-- (utilisation de LEFT JOIN)

SELECT Q.nom, COUNT(C.idCpt)
FROM Quartier Q
LEFT JOIN Compteur C ON C.idQ = Q.idQ
GROUP BY Q.nom;

/* 18 tuples : 
    Centre Ville	                        22
    Bellevue - Chantenay - Sainte Anne	    0
    Dervallières - Zola	                    1
    Hauts Pavés - Saint Félix	            4
    Malakoff - Saint-Donatien	            9
    ...                                     ...
*/

-- ---------------------------------------------------------------------------------------------------------

-- Requête 4 : Afficher le nombre d'enregistrement par quartier
-- (utilisation de LEFT JOIN)

SELECT Q.nom, COUNT(V.date)
FROM Quartier Q
LEFT JOIN Compteur C ON C.idQ = Q.idQ
LEFT JOIN nbVelos V ON V.idCpt = C.idCpt
GROUP BY Q.nom;

/* 18 tuples : 
    Centre Ville	                        24574
    Bellevue - Chantenay - Sainte Anne	    0
    Dervallières - Zola	                    1117
    Hauts Pavés - Saint Félix	            4468
    Malakoff - Saint-Donatien	            10053
    ...                                     ...
*/

-- ---------------------------------------------------------------------------------------------------------

-- Requête 5 : Afficher les températures des jours ou les compteurs ont enregistrés des passages et lorsque la température était positive
-- (utilisation de IN)

SELECT DISTINCT tempMoy
FROM Date
WHERE tempMoy IS NOT NULL
  AND tempMoy > 0
  AND date IN (
      SELECT date
      FROM nbVelos
  );


-- 761 tuples
-- les 5 premiers resultats
-- 7.279999999999988
-- 9.700000000000001
-- 10.799999999999994
-- 5.279999999999994
-- 6

-- ---------------------------------------------------------------------------------------------------------

-- Requête 6 : Afficher les compteurs qui n'ont pas de mesures avant 2022.
-- (utilisation de NOT IN)

SELECT *
FROM Compteur
WHERE idCpt NOT IN (
    SELECT idCpt
    FROM nbVelos
    WHERE date < '2022-01-01'
);

-- 2 tuples
-- les resultats
-- 700    Promenade de Bellevue vers Ouest    	10
-- 701    Promenade de Bellevue vers Est    	10

-- ---------------------------------------------------------------------------------------------------------

-- Requête 7 : Afficher les compteurs pour lesquels il existe au moins un jour ou la probabilité d’anomalie est forte
-- (utilisation de EXISTS)

SELECT DISTINCT c.idCpt, c.libelle
FROM Compteur c
WHERE EXISTS (
    SELECT * FROM nbVelos n
    WHERE n.idCpt = c.idCpt
    AND UPPER(n.probAnomalie) = 'FORTE'
);

-- 50 tuples
-- les 5 premiers resultats
-- 664    Bonduelle vers sud
-- 665    Bonduelle vers Nord
-- 666    Pont Audibert vers Sud
-- 667    Entrée pont Audibert vers Nord
-- 668    De Gaulle vers sud

-- ---------------------------------------------------------------------------------------------------------

-- Requête 8 : Afficher les compteurs pour lesquels il n’existe aucun risque (probabilité) d'anomalie
-- (utilisation de NOT EXISTS)

SELECT c.idCpt, c.libelle
FROM Compteur c
WHERE NOT EXISTS (
    SELECT * FROM nbVelos n
    WHERE n.idCpt = c.idCpt
    AND n.probAnomalie IS NOT NULL
);

-- les resultats
-- 700    Promenade de Bellevue vers Ouest
-- 701    Promenade de Bellevue vers Est
-- * null null
-- ---------------------------------------------------------------------------------------------------------

-- Requête 9 : Afficher la température moyenne maximale enregistrée (fonction d'agrégat sans GROUP BY)

SELECT tempMoy
FROM Date
WHERE tempMoy IS NOT NULL
ORDER BY tempMoy + 0 DESC
LIMIT 1;

-- 1 tuple
-- resultat 
-- 30.950000000000024

-- Requête 10 : Afficher le nombre total de compteurs enregistrés

SELECT COUNT(*) AS total_compteurs
FROM Compteur;

-- 1 tuple
-- resultat
-- 52
-- ---------------------------------------------------------------------------------------------------------

-- Requête 11 : Afficher le nombre de jours enregistrés par compteur (fonction d'agrégat avec GROUP BY)

SELECT idCpt, COUNT(*) AS nb_jours
FROM nbVelos
GROUP BY idCpt;

-- 50 tuples
-- les 5 premiers resultats
-- 664    1117
-- 665    1117
-- 666    1117
-- 667    1117
-- 668    1117
-- ---------------------------------------------------------------------------------------------------------

-- Requête 12 : Afficher le nombre d'enregistrements par jour de la semaine (1 = lundi, etc.)

SELECT jourSemaine, COUNT(*) AS nb_jours
FROM Date
GROUP BY jourSemaine;

-- 7 tuples
-- les 5 premiers resultats
--     3    159
--     4    160
--     5    159
--     6    160
--     7    159


-- ---------------------------------------------------------------------------------------------------------

-- Requetes 13 :
-- Moyenne de temperature par jour de la semaine qui est supérieur a 13.5
SELECT jourSemaine, AVG(tempMoy) AS moyenne_temp
FROM Date
GROUP BY jourSemaine
HAVING AVG(tempMoy) > 13.5;
-- 2 tuples
/* 
3	13.570943396226422
4	13.652312499999997
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requetes 14 :
-- Moyenne de la longeur des pistes par quartiers, mais on garde seulement ceux dong la moyenne dépasse les 1000 mètres. 
SELECT nom,
    AVG(longueurPiste) AS moyenne_longueur
FROM Quartier
GROUP BY nom HAVING AVG(longueurPiste) > 1000;
-- 18 tuples
/*
Centre Ville							21548.7
Bellevue - Chantenay - Sainte Anne		22597.3
Dervallières - Zola						4403.09
Hauts Pavés - Saint Félix				30522.9
Malakoff - Saint-Donatien				28078.6
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requetes 15 :
-- Compteurs qui ont enregistré des données tous les jours de la semaine
SELECT v.idCpt
FROM nbVelos v
JOIN Date d ON v.date = d.date
GROUP BY v.idCpt
HAVING COUNT(DISTINCT d.jourSemaine) = 7;
-- 50 tuples
/*
664
665
666
667
668
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requetes 16 :
-- Compteurs qui ont enregistré des données pendant les vacances
SELECT v.idCpt
FROM nbVelos v
JOIN Date d ON v.date = d.date
WHERE UPPER(d.vacances) <> 'HORS VACANCES'
GROUP BY v.idCpt
HAVING 
    COUNT(DISTINCT d.vacances) = (
        SELECT COUNT(DISTINCT vacances)
        FROM Date
        WHERE UPPER(vacances) != 'HORS VACANCES'
    )
    AND COUNT(*) = (
        SELECT COUNT(*)
        FROM nbVelos v2
        JOIN Date d2 ON v2.date = d2.date
        WHERE UPPER(d2.vacances) != 'HORS VACANCES' AND v2.idCpt = v.idCpt
    );
    -- 50 tuples
/*
664
665
666
667
668
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requetes 17
-- Compteurs qui ont enregistré des données tous les jours de la semaine (Similaire à la 15 mais ici avec VUE)
CREATE VIEW Vue_Compteurs_Jours_Complets AS
SELECT v.idCpt
FROM nbVelos v
JOIN Date d ON v.date = d.date
GROUP BY v.idCpt
HAVING COUNT(DISTINCT d.jourSemaine) = 7;
-- Utilisation
SELECT * FROM Vue_Compteurs_Jours_Complets;
-- 50 tuples
/*
664
665
666
667
668
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requetes 18 
-- Lister les comptages qui ont une anomalie de niveau "Forte" 
CREATE VIEW Vue_Comptages_Anormaux_Compteurs AS
SELECT *
FROM (
    SELECT *
    FROM nbVelos
    LIMIT 200
) AS sous
WHERE 
    UPPER(sous.probAnomalie) = 'FORTE';
-- Utilisation
SELECT * FROM Vue_Comptages_Anormaux_Compteurs;
-- 6 tuples
/*
664	2020-03-08	Forte
664	2020-05-20	Forte
664	2020-05-21	Forte
664	2020-05-22	Forte
664	2020-05-23	Forte
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requete 19 : 
-- Calculer la moyenne de de vélo par compteur
CREATE VIEW Vue_Moyenne_Velos_Par_Compteur AS
SELECT v.idCpt,
    AVG(e.nombre_velos) AS moyenne_velos
FROM nbVelos v
JOIN comptage_velo e ON v.idCpt = e.num_compteur AND v.date = e.dateMesure
GROUP BY v.idCpt;
-- Utilisation
SELECT * FROM Vue_Moyenne_Velos_Par_Compteur;
-- 50 tuples
/*
667	1751.8694
673	294.9490
725	326.8059
744	461.7782
674	472.3256
*/

-- ------------------------------------------------------------------------------------------------------------------------------------
-- Requetes 20 :
-- Nombre de quartiers sans compteur
CREATE VIEW Vue_Quartiers_Sans_Compteurs AS
SELECT q.idQ, q.nom
FROM Quartier q
LEFT JOIN quartier_compteur qc ON q.idQ = qc.idQuartier
WHERE qc.idCompteur IS NULL;

-- utilisation 
SELECT * FROM Vue_Quartiers_Sans_Compteurs;
-- 8 tuples
/*
2		Bellevue - Chantenay - Sainte Anne
7		Breil - Barberie
9		Nantes Erdre
14301	Trentemoult
14302	Hôtel de Ville
*/