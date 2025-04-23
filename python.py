import pandas as pd
from datetime import datetime

# --- Chargement des CSV ---
df_comptage = pd.read_csv("Données/comptageVelo.csv", sep=";")
df_compteurs = pd.read_csv("Données/compteurs.csv", sep=";")
df_longueur = pd.read_csv("Données/longueur_pistes_velo.csv", sep=";")
df_qc = pd.read_csv("Données/quartier_compteur.csv", sep=";")
df_quartiers = pd.read_csv("Données/quartiers.csv", encoding="latin1", sep=";")
df_temp = pd.read_csv("Données/temperature.csv", encoding="latin1", sep=";")

# --- Préparation des données ---

# Table Quartier
df_quartiers.rename(columns={'Identifiant': 'idQ', 'nom': 'nom'}, inplace=True)
df_longueur.rename(columns={'code Quartier': 'idQ', 'Amenagement cyclable': 'longueurPiste'}, inplace=True)
quartier_data = pd.merge(df_quartiers, df_longueur, on="idQ", how="left").drop_duplicates(subset='idQ')

# Table Compteur
df_compteurs.rename(columns={'Numéro': 'idCpt', 'Libellé': 'libelle'}, inplace=True)
compteur_data = df_compteurs[["idCpt", "libelle"]].drop_duplicates(subset="idCpt")

# Table Date
df_temp.rename(columns={'Date': 'date', 'TMoy (°C)': 'tempMoy'}, inplace=True)
df_temp["date"] = pd.to_datetime(df_temp["date"]).dt.date
df_temp = df_temp[df_temp["date"] <= datetime.today().date()]
df_temp["jourSemaine"] = pd.to_datetime(df_temp["date"]).dt.isocalendar().day
df_temp["vacances"] = "Hors Vacance"
date_data = df_temp[["date", "jourSemaine", "tempMoy", "vacances"]]

# Table nbVelos
df_comptage.rename(columns={
    'num compteur': 'idCpt',
    'date': 'date',
    'probabilite_presence_anomalie': 'probAnomalie'
}, inplace=True)
df_qc.rename(columns={'idCompteur': 'idCpt', 'idQuartier': 'idQ'}, inplace=True)
df_comptage["date"] = pd.to_datetime(df_comptage["date"]).dt.date
nb_velos_data = pd.merge(df_comptage, df_qc, on="idCpt", how="left")
nb_velos_data = nb_velos_data[["idQ", "idCpt", "date", "probAnomalie"]]

# --- Fonction d'écriture SQL ---
def write_insert_statements(df, table_name, f):
    for _, row in df.iterrows():
        columns = ", ".join([f"`{col}`" for col in df.columns])
        values = ", ".join(
            [f"'{str(val).replace('\'', '\'\'')}'" if pd.notnull(val) else "NULL" for val in row]
        )
        f.write(f"INSERT INTO `{table_name}` ({columns}) VALUES ({values});\n")

# --- Écriture dans un fichier .sql ---
with open("velo.sql", "w", encoding="utf-8") as f:
    f.write("""
-- Fichier SQL compatible MySQL

DROP TABLE IF EXISTS nbVelos;
DROP TABLE IF EXISTS Date;
DROP TABLE IF EXISTS Compteur;
DROP TABLE IF EXISTS Quartier;

CREATE TABLE Quartier (
    idQ INT PRIMARY KEY,
    nom TEXT,
    longueurPiste TEXT CHECK (CAST(longueurPiste AS DECIMAL(10,2)) >= 0)
);

CREATE TABLE Compteur (
    idCpt INT PRIMARY KEY,
    libelle TEXT
);

CREATE TABLE Date (
    date DATE PRIMARY KEY,
    jourSemaine TINYINT CHECK (jourSemaine >= 1 AND jourSemaine <= 7),
    tempMoy TEXT,
    vacances TEXT CHECK (vacances IN (
        'Hors Vacance', 'Pont de Ascension', 'Vacances de la Toussaint',
        'Vacances de Noël', 'Vacances de printemps', 'Vacances été', 'Vacances hiver'
    ))
);

CREATE TABLE nbVelos (
    idQ INT,
    idCpt INT,
    date DATE,
    probAnomalie TEXT CHECK (probAnomalie IN ('NULL', 'Faible', 'Forte')),
    PRIMARY KEY (idQ, idCpt, date),
    FOREIGN KEY (idQ) REFERENCES Quartier(idQ),
    FOREIGN KEY (idCpt) REFERENCES Compteur(idCpt),
    FOREIGN KEY (date) REFERENCES Date(date)
);


""")

    quartier_data = quartier_data.dropna(subset=["idQ"])
    compteur_data = compteur_data.dropna(subset=["idCpt"])
    date_data = date_data.dropna(subset=["date"])
    nb_velos_data = nb_velos_data.dropna(subset=["idQ", "idCpt", "date"])

    write_insert_statements(quartier_data, "Quartier", f)
    write_insert_statements(compteur_data, "Compteur", f)
    write_insert_statements(date_data, "Date", f)
    write_insert_statements(nb_velos_data, "nbVelos", f)

print("✅ Le fichier 'velo.sql' a été généré avec succès.")
