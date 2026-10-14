import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;


class ApplicationCentral {

    private Connection conn = null;
    private PreparedStatement insererue;
    private PreparedStatement inscriptionEtudiant;
    private PreparedStatement prerequis;
    private PreparedStatement ue_valide;
    private PreparedStatement visualiser_etudiants_bloc;
    private PreparedStatement visualiser_credit_pae;
    private PreparedStatement visualiser_pae_pas_valider;
    private PreparedStatement visualiser_ue_bloc;
    private final static Scanner sc = new Scanner(System.in);

    public ApplicationCentral() {
        try {
            Class.forName("org.postgresql.Driver");
        } catch (ClassNotFoundException e) {
            System.out.println("Driver PostgreSQL manquant !");
            System.exit(1);
        }
        String url = "jdbc:postgresql://localhost/Projet";
        try {
            conn = DriverManager.getConnection(url, "postgres", "azerty");
        } catch (
                SQLException e) {
            System.out.println("Impossible de joindre le server !" + e.getMessage());
            System.exit(1);
        }
        try {
            insererue = conn.prepareStatement("select  * from  Projet.insererue(?,?,?,?);");
            visualiser_pae_pas_valider = conn.prepareStatement("select * from Projet.visualiser_pae_pas_valider() t(nom varchar(40),prenom varchar(40),nombre_credit_valider integer);\n");
            visualiser_etudiants_bloc = conn.prepareStatement("select * from Projet.visualiser_etudiants_bloc(?) t(nom varchar(40),prenom varchar(40),nombre_credit_pae integer);");
            prerequis = conn.prepareStatement("SELECT * FROM Projet.prerequis(?,?);");
            inscriptionEtudiant = conn.prepareStatement("select * from Projet.insererEtudiantss(?,?,?,?);");
            ue_valide = conn.prepareStatement("SELECT * FROM Projet.ue_valide(?,?,?);");
            visualiser_credit_pae = conn.prepareStatement("select * from Projet.visualiser_credit_pae() t(nom varchar(40),prenom varchar(40),nombre_credit_pae integer,bloc integer);");
            visualiser_ue_bloc = conn.prepareStatement("select * from Projet.visualiser_ue_bloc(?)  t(nom varchar(60),code varchar(40),nombre_inscrit integer);");
        } catch (SQLException e) {
            System.out.println("Erreur lors de la preparation des statement");
            System.exit(1);
        }
    }

    public static void main(String[] args) {
        ApplicationCentral app = new ApplicationCentral();
        System.out.println("Bienvenue dans l'application Central");
        int choix, compteur;
        String[] table_choix = {"Ajouter une UE", "Ajouter un prerequis a une ue", "Ajouter un étudiant", "Valider une UE pour un étudiant", "Visualiser les etudiants d'un certain bloc", "Visualiser tous les étudiants et le nombre de credit de leur pae", "Visualiser étudiants qui n'ont pas validé leur pae", "Visualiser les ues d'un bloc"};
        do {
            compteur = 1;
            System.out.println("Que voulez-vous faire ?");
            for (String c : table_choix) {
                System.out.println(compteur + " : " + c);
                compteur++;
            }
            choix = boucleintTesteur();
            switch (choix) {
                case 1:
                    app.inscriptionUE();
                    break;
                case 2:
                    app.prerequis();
                    break;
                case 3:
                    app.inscriptionEtudiant();
                    break;
                case 4:
                    app.ue_valide();
                    break;
                case 5:
                    app.visualiser_etudiants_bloc();
                    break;
                case 6:
                    app.visualiser_credit_pae();
                    break;
                case 7:
                    app.visualiser_pae_pas_valider();
                    break;
                case 8:
                    app.visualiser_ue_bloc();
                    break;
                default:
                    break;
            }
        } while (choix >= 1 && choix <= table_choix.length);
    }

    private void visualiser_pae_pas_valider() {
        try {
            try (ResultSet rs = visualiser_pae_pas_valider.executeQuery()) {
                System.out.println("Voici la liste des étudiants qui n'ont pas validé leur pae : ");
                while (rs.next()) {
                    System.out.println("Nom : " + rs.getString(1) + "   " + "Prenom : " + rs.getString(2) + "   " + "Nombre de crédits de son PAE : " + rs.getInt(3));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void inscriptionUE() {
        System.out.println("Entrez le nom de l'ue");
        String nom = sc.nextLine();
        System.out.println("Entrez son bloc");
        Integer bloc = boucleintTesteur();
        System.out.println("Entrez son nombre credit");
        Integer nbCredit = boucleintTesteur();
        System.out.println("Entrez son code");
        String code = sc.nextLine();
        try {
            insererue.setString(1, nom);
            insererue.setInt(2, bloc);
            insererue.setInt(3, nbCredit);
            insererue.setString(4, code);
            insererue.executeQuery();
            System.out.println("L'ue " + code + " a bien été ajouté");
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void prerequis() {
        System.out.println("Entrez le code de l'ue concerné");
        String ueConcerne = sc.nextLine();
        System.out.println("Entrez le code de l'ue pré-requise ");
        String uePrerequise = sc.nextLine();
        try {
            prerequis.setString(1, ueConcerne);
            prerequis.setString(2, uePrerequise);
            prerequis.executeQuery();
            System.out.println("Le prerequis " + uePrerequise + " a bien été ajouter a l'ue " + ueConcerne);
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void inscriptionEtudiant() {
        String sel = BCrypt.gensalt();
        System.out.println("Entrez le nom");
        String nom = sc.nextLine();
        System.out.println("Entrez le prenom");
        String prenom = sc.nextLine();
        System.out.println("Entrez votre mail");
        String mail = sc.nextLine();
        System.out.println("Entrez votre mot de passe");
        String mdp = sc.nextLine();
        String mdpHash = BCrypt.hashpw(mdp, sel);
        try {
            inscriptionEtudiant.setString(1, nom);
            inscriptionEtudiant.setString(2, prenom);
            inscriptionEtudiant.setString(3, mail);
            inscriptionEtudiant.setString(4, mdpHash);
            inscriptionEtudiant.executeQuery();
            System.out.println("l'étudiant " + nom + " " + prenom + " à été ajouté");
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void ue_valide() {
        System.out.println("Entrez le prénom de l'étudiant");
        String prenomEtud = sc.nextLine();
        System.out.println("Entrez le nom de l'étudiant");
        String nomEtud = sc.nextLine();
        System.out.println("Entrez le NOM de l'UE ");
        String nomUE = sc.nextLine();
        try {
            ue_valide.setString(1, prenomEtud);
            ue_valide.setString(2, nomEtud);
            ue_valide.setString(3, nomUE);
            ue_valide.executeQuery();
            System.out.println("L'étudiant " + nomEtud + " " + prenomEtud + " a valider l'ue  " + nomUE);
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void visualiser_etudiants_bloc() {
        System.out.println("Entrez le bloc");
        Integer blocInt =boucleintTesteur();
        try {
            visualiser_etudiants_bloc.setInt(1, blocInt);
            try (ResultSet rs = visualiser_etudiants_bloc.executeQuery()) {
                System.out.println("Voici la liste des étudiants du bloc " + blocInt);
                while (rs.next()) {
                    System.out.println("Nom : " + rs.getString(1) + "   " + "Prenom : " + rs.getString(2) + "   " + "Nombre de crédits de son PAE : " + rs.getInt(3));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void visualiser_credit_pae() {
        try {
            try (ResultSet rs = visualiser_credit_pae.executeQuery()) {
                System.out.println("Voici la liste de tous les étudiants ");
                while (rs.next()) {
                    System.out.println("Nom : " + rs.getString(1) + "   " + "Prenom : " + rs.getString(2) + "   " + "Nombre de crédits de son PAE : " + rs.getInt(3) + "   " + "bloc : " + rs.getInt(4));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void visualiser_ue_bloc() {
        System.out.println("Entrez le bloc");
        Integer blocInt =boucleintTesteur();
        try {
            visualiser_ue_bloc.setInt(1, blocInt);
            try (ResultSet rs = visualiser_ue_bloc.executeQuery()) {
                System.out.println("Voici la liste des ues du bloc " + blocInt);
                while (rs.next()) {
                    System.out.println("Nom : " + rs.getString(1) + "   " + "Code : " + rs.getString(2) + "   " + "Nombre d'inscrit : " + rs.getInt(3));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private static boolean intTesteur(Object aTester) {
        Object x = 0;
        if (aTester.getClass() == x.getClass()) {
            return true;
        }
        return false;
    }

    private static int boucleintTesteur() {
        int aTester = -1;
        while (aTester == -1 || !intTesteur(aTester)) {
            try {
                aTester = Integer.parseInt(sc.nextLine());
                return aTester;
            } catch (NumberFormatException e) {
                System.out.println("Erreur, veuillez entrez un chiffre");
            }
        }
        return -1;
    }

}
