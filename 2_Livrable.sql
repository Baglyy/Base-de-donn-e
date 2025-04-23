---------------------------------------------------------------- CREATION DES TABLES BRUT ----------------------------------------------------------------
CREATE TABLE compteurs (
    numero INT,
    libelle VARCHAR(50)
);

CREATE TABLE longueur_pistes_velo (
    code INT,
    amenagement DOUBLE
);

CREATE TABLE quartiers (
    identifiant INT NOT NULL,
    nom VARCHAR(50) NOT NULL
);

CREATE TABLE temperature (
    dateMesure Date,
    tempMoy VARCHAR(50)
);

CREATE TABLE comptage_velo (
    num_compteur INT,
    dateMesure DATE,
    nombre_velos INT,
    probabilite_anomalie VARCHAR(50),
    jour_de_la_semaine INT,
    vacances VARCHAR(50)
);

CREATE TABLE quartier_compteur (
    idCompteur INT,
    idQuartier INT
);

---------------------------------------------------------------- CREATION DES TABLES DE L'UML ----------------------------------------------------------------
/* Shéma relationnel :
    Quartier(idQ(1), nom, longueurPiste)
    Compteur(idCpt(1), libelle, idQ=@Quartier.idQ)
    Date(date(1), jourSemaine, tempMoy, vacances)
    nbVelos([idCpt=@Compteur.idCpt, date=@Date.date](1), probAnomalie)

    Contraintes textuelles : 
    - Les variables idQ, idCpt, jourSemaine sont de type INT
    - La variable date est de type Date
    - La variable longueurPiste est de type double
    - Le reste est de type VARCHAR()
    - jourSemaine doit être compris entre 1 et 7 inclus
    - probAnomalie est soit NULL, Faible ou Forte
    - vacances peut être égale uniquement à : Hors Vacance, Pont de Ascension, Vacances de la Toussain, Vacances de Noël, Vacances de printemps, Vacances été, Vacances hiver
    - longueurPiste ne peut pas être inférieure à 0. 
*/


CREATE TABLE Quartier (
    idQ INT,
    nom VARCHAR(50),
    longueurPiste DOUBLE,
    CONSTRAINT pk_Quartier PRIMARY KEY (idQ),
    CONSTRAINT chk_longeurMin CHECK (longueurPiste >= 0)   
);

CREATE TABLE Compteur (
    idCpt INT NOT NULL,
    libelle VARCHAR(50),
    idQ INT,
	CONSTRAINT pk_Compteur PRIMARY KEY (idCpt),
    CONSTRAINT fk_Compteur_Quartier FOREIGN KEY (idQ) REFERENCES Quartier(idQ)
);


CREATE TABLE Date (
    date DATE NOT NULL,
    jourSemaine INT,
    tempMoy VARCHAR(50),
    vacances VARCHAR(50),
	CONSTRAINT pk_Date PRIMARY KEY (date),
    CONSTRAINT chk_intervalle CHECK (jourSemaine >= 1 AND jourSemaine <= 7),
    CONSTRAINT chk_valVac CHECK (UPPER(vacances) IN ('HORS VACANCES', 'PONT DE ASCENSION', 'VACANCES DE LA TOUSSAINT', 'VACANCES DE NOËL', 'VACANCES DE PRINTEMPS', 'VACANCES ÉTÉ', 'VACANCES HIVER'))
);

CREATE TABLE nbVelos (
    idCpt INT,
    date DATE,
    probAnomalie VARCHAR(50),
    PRIMARY KEY (idCpt, date),
    CONSTRAINT fk_nbVelos_compteur FOREIGN KEY (idCpt) REFERENCES Compteur(idCpt),
    CONSTRAINT fk_nbVelos_date FOREIGN KEY (date) REFERENCES Date(date),
    CONSTRAINT chk_valAnomalie CHECK (probAnomalie IS NULL OR UPPER(probAnomalie) IN ('FAIBLE', 'FORTE'))
);


---------------------------------------------------------------- INSERTION DES DONNEES ----------------------------------------------------------------
-- 1ère étape --> Insertion des données brutes à partir des fichiers csv grâce à un code python
-- 2ème étape --> Insertion des données dans les nouvelles tables à partir des tables brutes :

INSERT INTO Quartier (idQ, nom, longueurPiste)
SELECT q.identifiant, q.nom, l.amenagement
FROM quartiers q
JOIN longueur_pistes_velo l ON q.identifiant = l.code;

INSERT INTO Compteur (idCpt, libelle, idQ)
SELECT c.numero, c.libelle, q.identifiant
FROM compteurs c
JOIN quartier_compteur qc ON c.numero = qc.idCompteur
JOIN quartiers q ON qc.idQuartier = q.identifiant;

INSERT INTO Date (date, jourSemaine, tempMoy, vacances)
SELECT 
    c.dateMesure,
    MAX(c.jour_de_la_semaine),
    AVG(t.tempMoy),
    MAX(c.vacances)
FROM comptage_velo c
JOIN temperature t ON c.dateMesure = t.dateMesure
GROUP BY c.dateMesure;

INSERT INTO nbVelos (idCpt, date, probAnomalie)
SELECT c1.num_compteur, c1.dateMesure, c1.probabilite_anomalie
FROM comptage_velo c1
JOIN Compteur cp ON cp.idCpt = c1.num_compteur
JOIN Date d ON d.date = c1.dateMesure
WHERE NOT EXISTS (
    SELECT *
    FROM comptage_velo c2
    WHERE c2.num_compteur = c1.num_compteur
      AND c2.dateMesure = c1.dateMesure
      AND c2.probabilite_anomalie IS NOT NULL
      AND c1.probabilite_anomalie IS NULL
);












