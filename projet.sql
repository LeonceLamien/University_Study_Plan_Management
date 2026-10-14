DROP SCHEMA if exists Projet CASCADE;
CREATE SCHEMA Projet;

CREATE TABLE Projet.etudiants
(
    id_etudiant           SERIAL PRIMARY KEY           NOT NULL,
    nom                   character varying(40)        NOT NULL check ( nom <> ''),
    prenom                character varying(40)        NOT NULL check ( prenom <> ''),
    email                 character varying(40) UNIQUE NOT NULL check ( email SIMILAR TO '%@%.%'),
    mot_de_passe          character varying(60)        NOT NULL check ( mot_de_passe <> ''),
    bloc                  integer                      NULL     default 0 check (bloc IN (1, 2, 3)),
    pae_valide           boolean                      NOT NULL default false,
    nombre_credit_pae     integer                      NOT NULL default 0 check (nombre_credit_pae >= 0),
    nombre_credit_valider integer                      NOT NULL default 0 check (nombre_credit_valider >= 0)
);

CREATE TABLE Projet.unites_enseignement
(
    id_ue          SERIAL PRIMARY KEY           NOT NULL,
    code           character varying(40) UNIQUE NOT NULL,
    nom            character varying(60)        NOT NULL check ( nom <> ''),
    nombre_inscrit integer                      NOT NULL default 0 check (nombre_inscrit >= 0),
    bloc           integer                      not NULL check (bloc IN (1, 2, 3)),
    nombre_credit  integer                      NOT NULL check (nombre_credit > 0),
    check (code similar to 'BINV' || bloc || '%' )

);

CREATE TABLE Projet.prerequis_ue
(
    ue_concerne  INTEGER NOT NULL check ( ue_concerne <> ue_prerequis),
    ue_prerequis INTEGER NOT NULL check ( ue_concerne <> ue_prerequis),
    FOREIGN KEY (ue_concerne) REFERENCES Projet.unites_enseignement (id_ue),
    FOREIGN KEY (ue_prerequis) REFERENCES Projet.unites_enseignement (id_ue),
    PRIMARY KEY (ue_concerne, ue_prerequis)
);

CREATE TABLE Projet.ue_valides
(
    id_etudiant INTEGER NOT NULL,
    id_ue       INTEGER NOT NULL,
    FOREIGN KEY (id_etudiant) REFERENCES Projet.etudiants (id_etudiant),
    FOREIGN KEY (id_ue) REFERENCES Projet.unites_enseignement (id_ue),
    PRIMARY KEY (id_etudiant, id_ue)
);
CREATE TABLE Projet.lignes_pae
(
    id_etudiant INTEGER NOT NULL,
    id_ue       INTEGER NOT NULL,
    FOREIGN KEY (id_etudiant) REFERENCES Projet.etudiants (id_etudiant),
    FOREIGN KEY (id_ue) REFERENCES Projet.unites_enseignement (id_ue),
    PRIMARY KEY (id_etudiant, id_ue)
);
CREATE OR REPLACE FUNCTION Projet.bloc(email_etudiant VARCHAR(100)) RETURNS integer AS
$$
DECLARE
    id INTEGER := 0;
    record6 record;
BEGIN
    IF NOT EXISTS(SELECT *
                  FROM Projet.etudiants e
                  where e.email = email_etudiant) THEN
        RAISE 'Etudiant inconnue';
    END IF;
      select sum(ue.nombre_credit) + e.nombre_credit_valider as sommme
    from Projet.lignes_pae pae,
         Projet.etudiants e,
         Projet.unites_enseignement ue
    where e.id_etudiant = pae.id_etudiant
      and ue.id_ue = pae.id_ue
      and e.email = email_etudiant
    group by e.nombre_credit_valider
    into record6;
    if(record6.sommme=180) then
         Update Projet.etudiants e
        set bloc=3
        where e.email = email_etudiant
          and e.nombre_credit_valider + e.nombre_credit_pae = 180
        RETURNING bloc INTO id;
         return  id;
end if;

    IF EXISTS(SELECT *
              FROM Projet.etudiants e
              where e.email = email_etudiant
                and e.nombre_credit_valider < 45
                and e.bloc is null) then
        Update Projet.etudiants e
        set bloc=1
        where  e.email = email_etudiant
          and e.nombre_credit_valider < 45
        RETURNING bloc INTO id;
         return  id;
    END IF;
    Update Projet.etudiants e
    set bloc=2
    where  e.email = email_etudiant
      and e.bloc is null
    RETURNING bloc INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.insererEtudiantss(nom_source VARCHAR(100), prenom_source VARCHAR(100),
                                                    email_source VARCHAR(100),
                                                    mdp VARCHAR(100))
    RETURNS INTEGER AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    IF EXISTS(SELECT *
              FROM Projet.etudiants e
              WHERE e.email = email_source) THEN
        RAISE 'Etudiants deja inscrit';
    END IF;
    INSERT INTO Projet.etudiants
    VALUES (DEFAULT, nom_source, prenom_source, email_source, mdp, null, false, 0, 0)
    RETURNING id_etudiant INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.insererue(nom_source VARCHAR(100), _bloc integer,
                                            _nombre_credit integer, _code_eu varchar(100))
    RETURNS INTEGER AS
$$
DECLARE
    id INTEGER := 0;
BEGIN
    IF EXISTS(SELECT *
              FROM Projet.unites_enseignement ue
              WHERE ue.code = _code_eu) THEN
        RAISE 'UE deja encodée';
    END IF;
    INSERT INTO Projet.unites_enseignement
    VALUES (DEFAULT, _code_eu, nom_source, 0, _bloc, _nombre_credit)
    RETURNING id_ue INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION Projet.prerequis(_ue_concerne VARCHAR(100), _ue_prerequis varchar(100))
    RETURNS INTEGER AS
$$
DECLARE
    id     INTEGER := 0;
    recor1 RECORD;
    recor2 RECORD;
BEGIN
    select id_ue, ue.bloc from Projet.unites_enseignement ue where ue.code = _ue_prerequis into recor1;
    if (recor1.id_ue is null) then
        RAISE ' id prerequis is null ';
    END IF;

    select ue.id_ue, ue.bloc from Projet.unites_enseignement ue where ue.code = _ue_concerne into recor2;
    if (recor2.id_ue is null) then
        RAISE ' id concerne is null';
    END IF;

    if (recor1.bloc >= recor2.bloc) then
        RAISE 'un prerequis ne peut pas etre appliquer à un ue de bloc inferieur ou egal';
    end if;
    INSERT INTO Projet.prerequis_ue
    VALUES (recor2.id_ue, recor1.id_ue)
    RETURNING ue_concerne,ue_prerequis INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.ue_valide(nom_source VARCHAR(100), prenom_source varchar(100), nom_ue varchar(100))
    RETURNS INTEGER AS
$$
DECLARE
    id                   INTEGER := 0;
    id_etudiant_concerne INTEGER := 0;
    id_ue_concerne       INTEGER := 0;
BEGIN
    select id_ue from Projet.unites_enseignement ue where ue.nom = nom_ue into id_ue_concerne;

    if (id_ue_concerne is null) then
        RAISE ' id ue is null ';
    END IF;


    select id_etudiant
    from Projet.etudiants e
    where e.nom = nom_source
      and e.prenom = prenom_source
    into id_etudiant_concerne;
    if (id_etudiant_concerne is null) then
        RAISE ' id etudiant is null';
    END IF;


    INSERT INTO Projet.ue_valides
    VALUES (id_etudiant_concerne, id_ue_concerne)
    RETURNING id_etudiant,id_ue INTO id;
    RETURN id;
END;
$$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION Projet.nombre_credit_valider() RETURNS TRIGGER AS
$$
DECLARE
BEGIN

    update Projet.etudiants e
    set nombre_credit_valider=nombre_credit_valider + ue.nombre_credit
    FROM Projet.unites_enseignement ue,
         Projet.ue_valides
    where ue.id_ue = new.id_ue
      and e.id_etudiant = new.id_etudiant;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_nombre_credit
    AFTER insert
    ON Projet.ue_valides
    FOR EACH ROW
EXECUTE PROCEDURE Projet.nombre_credit_valider();

CREATE OR REPLACE FUNCTION Projet.visualiser_etudiants_bloc(_bloc integer) RETURNS SETOF RECORD AS
$$
DECLARE
    etudiants RECORD;
BEGIN
    FOR etudiants IN select e.nom, e.prenom, e.nombre_credit_pae
                     from Projet.etudiants e
                     where e.bloc = _bloc
                     order by e.nom
        LOOP
            return next etudiants;
        END LOOP;
    if (etudiants is null) then
        raise 'la liste d etudiant est vide';
    end if;
    return;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.visualiser_credit_pae() RETURNS SETOF RECORD AS
$$
DECLARE
    etudiants RECORD;
BEGIN
    FOR etudiants IN select e.nom, e.prenom, e.nombre_credit_pae, coalesce(e.bloc, null)
                     from Projet.etudiants e
                     order by e.nombre_credit_pae
        LOOP
            return next etudiants;
        END LOOP;
    if (etudiants = null) then
        raise 'liste d etudiant vide';
    end if;
    return;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.visualiser_pae_pas_valider() RETURNS SETOF RECORD AS
$$
DECLARE
    etudiants RECORD;
BEGIN
    FOR etudiants IN select e.nom, e.prenom, e.nombre_credit_valider from Projet.etudiants e where e.pae_valide = False
        LOOP
            return next etudiants;
        END LOOP;
    if (etudiants = null) then
        raise 'liste d etudiant vide';
    end if;
    return;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.visualiser_ue_bloc(_bloc integer) RETURNS SETOF RECORD AS
$$
DECLARE
    record RECORD;
BEGIN
    FOR record IN select ue.nom, ue.code, nombre_inscrit
                  from Projet.unites_enseignement ue
                  where ue.bloc = _bloc
                  order by ue.nombre_inscrit
        LOOP
            return next record;
        END LOOP;
    if (record = null) then
        raise 'liste d ue vide';
    end if;
    return;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.ajouter_ue_pae(_ue varchar(100), mail varchar(100)) RETURNS integer AS
$$
DECLARE
    id              integer := 0;
    id_etu          integer := 0;
    id_uee          integer := 0;
    bloc_ue         integer := 0;
    liste_ue_valide record;
    test            record;
BEGIN
    select e.id_etudiant from Projet.etudiants e where e.email = mail into id_etu;
    select ue.id_ue from Projet.unites_enseignement ue where ue.nom = _ue into id_uee;
    select ue.bloc from Projet.unites_enseignement ue where ue.nom = _ue into bloc_ue;
    if EXISTS(select * from Projet.etudiants e where e.email = mail and e.pae_valide = TRUE) then
        raise 'PAE deja valider';
    end if;
    if exists(select * from Projet.ue_valides uev where uev.id_etudiant = id_etu and uev.id_ue = id_uee) then
        raise 'UE deja valide';
    end if;
    if exists(select e.id_etudiant
              from Projet.etudiants e
              where nombre_credit_valider < 30 and id_etudiant = id_etu and bloc_ue != 1)
    then
        raise ' peut pas choisir des ue du bloc 2 ou 3';
    end if;

    FOR liste_ue_valide IN select distinct pue.ue_prerequis
                           from Projet.prerequis_ue pue
                           where pue.ue_concerne =
                                 (select ue.id_ue from Projet.unites_enseignement ue where ue.nom = _ue)
        loop
            select distinct uev.id_ue
            from Projet.ue_valides uev,
                 Projet.etudiants e
            where uev.id_etudiant = id_etu
              and uev.id_ue = liste_ue_valide.ue_prerequis
            into test;
            if (test.id_ue is null) then raise 'prerequis non validé'; end if;

        END LOOP;

    insert into Projet.lignes_pae
    values (id_etu, id_uee)
    returning id_etudiant,id_ue into id;
    return id;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.enlever_ue_pae(_ue varchar(100), mail varchar(100)) RETURNS integer AS
$$
DECLARE
    id     integer := 0;
    id_etu integer := 0;
    id_uee integer := 0;
BEGIN
    select e.id_etudiant from Projet.etudiants e where e.email = mail into id_etu;
    select ue.id_ue from Projet.unites_enseignement ue where ue.nom = _ue into id_uee;
    if EXISTS(select * from Projet.etudiants e where e.email = mail and e.pae_valide = TRUE) then
        raise 'retrait impossible car PAE deja valider';
    end if;
    if not exists(select *
                  from Projet.lignes_pae lpae,
                       Projet.etudiants e,
                       Projet.unites_enseignement ue
                  where e.id_etudiant = lpae.id_etudiant
                    and ue.id_ue = lpae.id_ue
                    and ue.nom = _ue
                    and e.email = mail) then
        raise 'retrait impossible car cette ue ne se trouve pas dans votre pae';
    end if;
    delete
    from Projet.lignes_pae lpae
    where lpae.id_etudiant = id_etu
      and lpae.id_ue = id_uee
    returning id_etudiant,id_ue into id;
    return id;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.valider_pae(mail varchar(100)) RETURNS VOID AS
$$
DECLARE
    id      integer := 0;
    record  RECORD;
    record2 RECORD;
    record3 RECORD;
    record5 RECORD;
    record6 RECORD;
BEGIN
    if exists(select * from Projet.etudiants e where e.email = mail and e.pae_valide = TRUE) then
        raise 'Pae deja valider' ;
    end if;
    select ue.nom
    from Projet.lignes_pae pae,
         Projet.etudiants e,
         Projet.unites_enseignement ue
    where e.id_etudiant = pae.id_etudiant
      and ue.id_ue = pae.id_ue
      and e.email = mail
    into record5;
    select sum(ue.nombre_credit) + e.nombre_credit_valider as sommme
    from Projet.lignes_pae pae,
         Projet.etudiants e,
         Projet.unites_enseignement ue
    where e.id_etudiant = pae.id_etudiant
      and ue.id_ue = pae.id_ue
      and e.email = mail
    group by e.nombre_credit_valider
    into record6;
    select sum(ue.nombre_credit) as sommme
    from Projet.lignes_pae pae,
         Projet.etudiants e,
         Projet.unites_enseignement ue
    where e.id_etudiant = pae.id_etudiant
      and ue.id_ue = pae.id_ue
      and e.email = mail
    group by e.nombre_credit_valider
    into record;
    if (record6.sommme = 180) then
        if (record.sommme <= 74) then
            Update Projet.etudiants e
            set pae_valide= TRUE,
                nombre_credit_pae=record.sommme
            where e.email = mail
            RETURNING e.id_etudiant INTO id;
            perform Projet.bloc( mail);
            RETURN;
        end if;
    end if;
    select sum(ue.nombre_credit) as sommme
    from Projet.etudiants e,
         Projet.unites_enseignement ue,
         Projet.lignes_pae pae
    where e.id_etudiant = pae.id_etudiant
      and ue.id_ue = pae.id_ue
      and e.email = mail
      and e.nombre_credit_valider < 45
    into record2;
    if (record2.sommme <= 60) then
        Update Projet.etudiants e
        set pae_valide= TRUE,
            nombre_credit_pae=record2.sommme
        where e.email = mail
        RETURNING e.id_etudiant INTO id;
        perform Projet.bloc( mail);
        RETURN;
    end if;
    select sum(ue.nombre_credit) as sommme
    from Projet.etudiants e,
         Projet.unites_enseignement ue,
         Projet.lignes_pae pae
    where e.id_etudiant = pae.id_etudiant
      and ue.id_ue = pae.id_ue
      and e.email = mail
      and e.nombre_credit_valider > 45
    into record3;
    if (record3.sommme BETWEEN 55 and 74) then
        Update Projet.etudiants e
        set pae_valide= TRUE,
            nombre_credit_pae=record3.sommme
        where e.email = mail
        RETURNING e.id_etudiant INTO id;
         perform Projet.bloc( mail);
        RETURN;
    end if;
    RAISE 'VALIDATION IMPOSIBLE';

END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.nombre_inscript() RETURNS TRIGGER AS
$$
DECLARE
BEGIN
    update Projet.unites_enseignement ue
    set nombre_inscrit=nombre_inscrit + 1
    FROM Projet.lignes_pae pae
    where pae.id_etudiant = new.id_etudiant
      and ue.id_ue = pae.id_ue;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_nombre_inscrit
    AFTER UPDATE of nombre_credit_pae
    ON Projet.etudiants
    FOR EACH ROW
EXECUTE PROCEDURE Projet.nombre_inscript();

CREATE OR REPLACE FUNCTION Projet.afficherUE_pae(mail varchar(100)) RETURNS setof record AS
$$
DECLARE
    record  RECORD;
    record1 RECORD;
    record2 RECORD;
    record3 RECORD;
    blocetu record;
    blocetudiant integer :=0;
BEGIN
select e.nombre_credit_valider from Projet.etudiants e where e.email = mail into blocetu;
if(blocetu.nombre_credit_valider between 61 and 120)then blocetudiant=2;
end if;
if(blocetu.nombre_credit_valider between 0 and 60)then blocetudiant=1;
end if;

if(blocetu.nombre_credit_valider between 121 and 180)then blocetudiant=3;
end if;

    select e.nombre_credit_valider from Projet.etudiants e where e.email = mail into record3;
    if (record3.nombre_credit_valider >= 30) then

        FOR record IN select distinct ue.nom
                      from Projet.unites_enseignement ue
                      where ue.id_ue not in (select uev.id_ue
                                             from Projet.ue_valides uev,
                                                  Projet.etudiants e
                                             where e.id_etudiant = uev.id_etudiant
                                               and e.email = mail)
            LOOP
                FOR record1 IN select distinct ue.nom
                               from Projet.unites_enseignement ue
                               where ue.id_ue not in (select pae.id_ue
                                                      from Projet.lignes_pae pae,
                                                           Projet.etudiants e
                                                      where e.id_etudiant = pae.id_etudiant
                                                        and e.email = mail)
                    LOOP
                        if (record1.nom = record.nom) then
                            FOR record2 IN select distinct ue.nom
                                           from Projet.unites_enseignement ue,
                                                Projet.prerequis_ue pue
                                           where ue.id_ue = pue.ue_concerne
                                             and pue.ue_prerequis in (select uev.id_ue
                                                                      from Projet.ue_valides uev,
                                                                           Projet.etudiants e
                                                                      where e.id_etudiant = uev.id_etudiant
                                                                        and e.email = mail)
                                LOOP
                                    if (record2.nom = record1.nom) then
                                        RETURN next record2 ;
                                    end if;
                                end loop;
                        end if;
                    end loop;
            end loop;
    end if;

    FOR record3 IN select ue.nom
                   from Projet.unites_enseignement ue
                   where ue.bloc = blocetudiant
                     and ue.id_ue not in (select uev.id_ue
                                          from Projet.ue_valides uev,
                                               Projet.etudiants e
                                          where e.id_etudiant = uev.id_etudiant
                                            and e.email = mail)
        LOOP
            FOR record1 IN select distinct ue.nom
                           from Projet.unites_enseignement ue
                           where ue.id_ue not in (select pae.id_ue
                                                  from Projet.lignes_pae pae,
                                                       Projet.etudiants e
                                                  where e.id_etudiant = pae.id_etudiant
                                                    and e.email = mail)
                LOOP
                    if (record1.nom = record3.nom) then
                        return next record3;
                    end if;
                end loop;
        end loop;
    return;

END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION Projet.visualiser_pae(mail varchar(100)) RETURNS setof record AS
$$
DECLARE
    record RECORD;
BEGIN
    FOR record IN select ue.nom, ue.bloc, ue.code, ue.nombre_credit
                  from Projet.unites_enseignement ue,
                       Projet.etudiants e,
                       Projet.lignes_pae pae
                  where ue.id_ue = pae.id_ue
                    and e.id_etudiant = pae.id_etudiant
                    and e.email = mail
                  order by 3
        LOOP
            return next record;
        end loop;
    return;

END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Projet.reinitialiser_PAE(mail VARCHAR(100)) RETURNS integer AS
$$
DECLARE
    id     integer := 0;
    record RECORD;
    id_etu INTEGER := 0;
BEGIN
    select et.id_etudiant from Projet.etudiant_tout et where et.email = mail into id_etu;

    if exists(select * from Projet.etudiants e where e.email = mail and e.pae_valide = TRUE) then
        raise 'réinitialisation impossible car PAE deja valider';
    end if;
    FOR record IN select pae.id_ue
                  from Projet.unites_enseignement ue,
                       Projet.etudiants e,
                       Projet.lignes_pae pae
                  where ue.id_ue = pae.id_ue
                    and e.id_etudiant = pae.id_etudiant
                    and e.email = mail
        LOOP
            delete
            from Projet.lignes_pae
            where Projet.lignes_pae.id_ue = record.id_ue
              and Projet.lignes_pae.id_etudiant = id_etu
            returning id_etudiant,id_ue into id;
        end loop;
    RETURN id;

END
$$ LANGUAGE plpgsql;


CREATE VIEW Projet.etudiant_tout AS
select e.*
from Projet.etudiants e;

CREATE OR REPLACE FUNCTION Projet.seConnecter(mail VARCHAR(100)) RETURNS setof record AS
$$
DECLARE
    record RECORD;
BEGIN
    select e.mot_de_passe from Projet.etudiants e where e.email = mail into record;
    if (record is null) then
        raise 'mot de passe ou email incorrect' ;
    end if;
    return next record;
END
$$ LANGUAGE plpgsql;
select * from Projet.afficherUE_pae('VANDERMEULEN@gmail.com') t(nom varchar(60));;
select *
from Projet.insererEtudiantss('DAMAS', 'DAMAS', 'DAMAS@gmail.com', '$2a$10$ktxuXOSl1Nm3kl8u8MIAcOPrEZrdnoonaPunw2JHp1W1KuCmyJ64a');
select *
from Projet.insererEtudiantss('FERNEEUW', 'FERNEEUW', 'FERNEEUW@gmail.com', '$2a$10$3GoWv8Si9jxiKffwIgcs4.qBf2cfqz6Kiu3Kfyson6WI0/LswtEEu');
select *
from Projet.insererEtudiantss('VANDER MEULEN', 'VANDER MEULEN', 'VANDERMEULEN@gmail.com', '$2a$10$D8GsTbX5AsbeOUw.LmBxgOluiL6wMLBsrLLhykWKKxVC8nSOc7A1K');
select *
from Projet.insererEtudiantss('LECONTE', 'LECONTE', 'LECONTE@gmail.com', '$2a$10$2Z3BWAHIFsFP6AZnHMBtZuKTBsOg.DrbZ2C/QYX8SXawT649MsvMC');

select *
from Projet.insererue('BD1', 1, 31, 'BINV11');
select *
from Projet.insererue('APOO', 1, 16, 'BINV12');
select *
from Projet.insererue('ALGO', 1, 13, 'BINV13');
select *
from Projet.insererue('BD2', 2, 42, 'BINV21');
select *
from Projet.insererue('ANGLAIS', 3, 16, 'BINV311');
select *
from Projet.insererue('STAGE', 3, 44, 'BINV32');



select *
from Projet.prerequis('BINV21', 'BINV11');
select *
from Projet.prerequis('BINV32', 'BINV21');

select *
from Projet.ue_valide('DAMAS', 'DAMAS', 'APOO');
select *
from Projet.ue_valide('DAMAS', 'DAMAS', 'ALGO');
select *
from Projet.ue_valide('FERNEEUW', 'FERNEEUW', 'BD1');
select *
from Projet.ue_valide('FERNEEUW', 'FERNEEUW', 'APOO');
select *
from Projet.ue_valide('VANDER MEULEN', 'VANDER MEULEN', 'BD1');
select *
from Projet.ue_valide('VANDER MEULEN', 'VANDER MEULEN', 'APOO');
select *
from Projet.ue_valide('VANDER MEULEN', 'VANDER MEULEN', 'ALGO');
select *
from Projet.ue_valide('LECONTE', 'LECONTE', 'BD1');
select *
from Projet.ue_valide('LECONTE', 'LECONTE', 'APOO');
select *
from Projet.ue_valide('LECONTE', 'LECONTE', 'ALGO');
select *
from Projet.ue_valide('LECONTE', 'LECONTE', 'BD2');
select *
from Projet.ue_valide('LECONTE', 'LECONTE', 'STAGE');

GRANT CONNECT ON DATABASE dbromanallion TO sienoulamien;
GRANT USAGE ON SCHEMA projet TO sienoulamien;
GRANT SELECT ON projet.etudiants, projet.lignes_pae, projet.unites_enseignement, projet.prerequis_ue, projet.ue_valides,projet.etudiant_tout TO sienoulamien;
GRANT UPDATE ON projet.lignes_pae, projet.unites_enseignement, projet.etudiants TO sienoulamien;
GRANT DELETE ON projet.lignes_pae TO sienoulamien;
GRANT INSERT ON projet.lignes_pae TO sienoulamien;




















