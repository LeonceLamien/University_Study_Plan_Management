<div align="center">

# University Study Plan Management

*Design of a PostgreSQL database and Java applications for managing annual study plans*

![Java](https://img.shields.io/badge/Java-JDBC-orange.svg)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-PL%2FpgSQL-blue.svg)
![Project](https://img.shields.io/badge/Project-academic-green.svg)

[Overview](#overview) • [Features](#features) • [Data Model](#data-model) • [Setup](#installation-and-usage) • [Structure](#repository-structure)

</div>

---

## Overview

This project implements a system for managing **annual study plans (PAEs)**. It combines a PostgreSQL relational schema, PL/pgSQL functions and triggers, and two Java command-line applications connected to the database through JDBC.

The applications separate administrative tasks from student-facing operations. The database centralizes courses (UEs), their prerequisites, earned credits, and the courses selected for each study plan.

## Features

### Administration

- Register students and create courses.
- Define prerequisites between courses.
- Record courses passed by a student.
- View students by study block, their study-plan credits, and unvalidated plans.
- View courses in a study block and their enrollment counts.

### Student portal

- Sign in with an email address and password.
- View available courses and their prerequisites.
- Add or remove courses from a study plan before it is validated.
- View and reset a study plan before validation.
- Validate a study plan when the business rules allow it.

### Database-enforced rules

- Enforce uniqueness and validate study blocks and credit values.
- Check prerequisites and study-block eligibility when selecting courses.
- Automatically update earned credits and enrollment counts using triggers.
- Hash passwords with BCrypt in the Java application.

## Data Model

The main tables are:

| Table | Purpose |
|---|---|
| `etudiants` | Student information, study block, and credits |
| `unites_enseignement` | Course catalog, study blocks, and credits |
| `prerequis_ue` | Prerequisite relationships between courses |
| `ue_valides` | Courses passed by students |
| `lignes_pae` | Courses included in each study plan |

PL/pgSQL functions implement business rules and queries. The `etudiant_tout` view and database triggers complement the model.

## Technologies

- **Java** and **JDBC**
- **PostgreSQL** and **PL/pgSQL**
- PostgreSQL JDBC driver included in `projet_sql copie/lib/`
- BCrypt implementation included in `projet_sql copie/src/BCrypt.java`

## Installation and Usage

### Prerequisites

- PostgreSQL installed and running.
- A JDK providing `javac` and `java`.
- The PostgreSQL JDBC driver included in the repository.

### Set up the database

1. Create a PostgreSQL database named `Projet`.
2. Review `projet.sql` before running it: the script starts by dropping the `Projet` schema with `CASCADE`, then recreates it and inserts sample data.
3. Adjust or remove the `GRANT` statements at the end of the file if the roles and database referenced there do not exist in your environment.
4. Run the script against a test database:

```bash
psql -d Projet -f projet.sql
```

> **Warning:** Running this script resets the `Projet` schema and deletes the objects it contains. Do not run it on a database containing data you want to keep.

### Configure and compile the applications

Both applications currently connect to a local `Projet` database. Before launching them, configure appropriate PostgreSQL credentials in the `ApplicationCentral` and `ApplicationEtudiant` constructors.

> **Before publishing this repository:** database credentials are currently hard-coded in the Java source. Replace them with local configuration or environment variables, and make sure no real credentials are tracked by Git.

From the Java project directory:

```bash
cd "projet_sql copie"
mkdir -p out
javac -cp "lib/postgresql-42.2.18.jar" -d out src/*.java
```

### Run the applications

From the same directory, launch either the administration or student application:

```bash
java -cp "out:lib/postgresql-42.2.18.jar" ApplicationCentral
```

```bash
java -cp "out:lib/postgresql-42.2.18.jar" ApplicationEtudiant
```

The `:` classpath separator is used on macOS and Linux. On Windows, replace it with `;`.

## Repository Structure

```text
.
├── projet.sql
└── projet_sql/
    ├── lib/
    │   └── postgresql-42.2.18.jar
    └── src/
        ├── ApplicationCentral.java
        ├── ApplicationEtudiant.java
        └── BCrypt.java
```


## License

No license is specified in this repository. Contact the authors before reusing or redistributing this project.
