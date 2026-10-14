
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Scanner;


class ApplicationEtudiant {

    private Connection conn = null;
    private PreparedStatement seConnecter;
    private PreparedStatement afficherUE_pae;
    private PreparedStatement ajouter_ue_pae;
    private PreparedStatement enlever_ue_pae;
    private PreparedStatement visualiser_pae;
    private PreparedStatement valider_pae;
    private PreparedStatement reinitialisePAE;
    private final static Scanner sc = new Scanner(System.in);


    public ApplicationEtudiant() {
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
            System.out.println("Impossible de joindre le server !");
            System.exit(1);
        }
        try {
            seConnecter = conn.prepareStatement("select*from Projet.seConnecter(?)t(mot_de_passe varchar(60));");
            ajouter_ue_pae = conn.prepareStatement("select * from Projet.ajouter_ue_pae(?,?);");
            enlever_ue_pae = conn.prepareStatement("select * from Projet.enlever_ue_pae(?,?);");
            valider_pae = conn.prepareStatement("select * from Projet.valider_pae(?);");
            afficherUE_pae = conn.prepareStatement("select * from Projet.afficherUE_pae(?) t(nom varchar(60));");
            visualiser_pae = conn.prepareStatement("select * from Projet.visualiser_pae(?)t(nom character varying(60),bloc integer, code character varying(40),nombre_credit integer);");
            reinitialisePAE = conn.prepareStatement("select * from Projet.reinitialiser_PAE(?);");
        } catch (SQLException e) {
            System.out.println("Erreur lors de la preparation des statement");
            System.exit(1);
        }
    }

    public static void main(String[] args) {
        ApplicationEtudiant app = new ApplicationEtudiant();
        System.out.println("Bienvenue dans l'application Etudiant");
        System.out.println("Veuillez vous connectez");
        boolean estConnecte = false;
        while (!estConnecte) {
            if (app.seConnecter() == true) {
                estConnecte = true;
            }
        }
        int choix, compteur;
        String[] table_choix = {"Ajouter une ue à son pae", "Enlever une ue à son pae", "Valider son pae", "Afficher les ues que l'on peut ajouter à son pae", "Visualiser son pae", "Réinitialiser son pae"};
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
                    app.ajouter_ue_pae();
                    break;
                case 2:
                    app.enlever_ue_pae();
                    break;
                case 3:
                    app.valider_pae();
                    break;
                case 4:
                    app.afficherUE_pae();
                    break;
                case 5:
                    app.visualiser_pae();
                    break;
                case 6:
                    app.reinitialisePAE();
                    break;
                default:
                    break;
            }
        } while (choix >= 1 && choix <= table_choix.length);
    }

    private String email;

    private boolean seConnecter() {
        boolean temp = false;
        System.out.println("Entrez votre adresse mail");
        String mail = sc.nextLine();
        System.out.println("Entrez votre mot de passe");
        String mdp = sc.nextLine();
        try {
            seConnecter.setString(1, mail);
            try (ResultSet rs = seConnecter.executeQuery()) {
                if (rs.next() == false) {
                    System.out.println("erreur");
                    return false;
                }
                if (BCrypt.checkpw(mdp, rs.getString(1))) {
                    temp = true;
                    email = mail;
                }
            }
        } catch (SQLException e) {
        }
        return temp;
    }

    private void ajouter_ue_pae() {
        System.out.println("Entrez l'ue à ajouter dans votre pae");
        String ue = sc.nextLine();
        try {
            ajouter_ue_pae.setString(1, ue);
            ajouter_ue_pae.setString(2, email);
            ajouter_ue_pae.executeQuery();
            System.out.println("L'ue " + ue + " à bien été  ajoutée dans votre pae");
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void enlever_ue_pae() {
        System.out.println("Entrez le nom de l'ue à supprimer de votre pae");
        String nom = sc.nextLine();
        try {
            enlever_ue_pae.setString(1, nom);
            enlever_ue_pae.setString(2, email);
            enlever_ue_pae.executeQuery();
            System.out.println("L'ue " + nom + " à bien été  supprimée dans votre pae");
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void valider_pae() {
        try {
            valider_pae.setString(1, email);
            valider_pae.executeQuery();
            System.out.println("Votre pae à bien été validé");
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void afficherUE_pae() {
        try {
            afficherUE_pae.setString(1, email);
            try (ResultSet rs = afficherUE_pae.executeQuery()) {
                System.out.println("Voici la liste des ues que vous pouvez ajouter dans votre pae :");
                while (rs.next()) {
                    System.out.println(rs.getString(1));
                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void visualiser_pae() {
        try {
            visualiser_pae.setString(1, email);
            try (ResultSet rs = visualiser_pae.executeQuery()) {
                System.out.println("Voici les ues de votre pae");
                while (rs.next()) {
                    System.out.println("Nom : " + rs.getString(1) + "   " + "Bloc : " + rs.getInt(2) + "   " + "Code : " + rs.getString(3) + "   " + "Nombre de crédit : " + rs.getInt(4));

                }
            }
        } catch (SQLException e) {
            System.out.println(e.getMessage().split("\n")[0]);
        }
    }

    private void reinitialisePAE() {
        try {
            reinitialisePAE.setString(1, email);
            reinitialisePAE.executeQuery();
            System.out.println("Votre pae à bien été reinitialisé");
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