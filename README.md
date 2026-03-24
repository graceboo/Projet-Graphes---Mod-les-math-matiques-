# Projet Graphes- Modèle Mathématique
Projet de modèle mathématique en Julia
Membres : Grace SILVA, Sandra OUBAKOUK

Contenu du programme :
- Question 1 : calcul du flot maximal P(a,b)
- Question 2 : calcul de la SEC d’un graphe
- Question 3 : détermination d’une coupe minimale et des arêtes à supprimer
- Question 4 : génération d’un graphe orienté fortement connexe de 1000 sommets, puis calcul de sa SEC

Packages utilisés :
- JuMP
- Cbc
- Random
- MathOptInterface

Exécution :
Lancer simplement le fichier Julia.
Le programme affiche :
- les résultats pour les graphes G3, G4, G5, G1, G2
- le couple donnant le minimum
- les arêtes minimales à supprimer
- le résultat de la question 4 (Si on décommente la ligne 281 du code)

Résultats obtenus :
- SEC(G3) = 2
- SEC(G4) = 2
- SEC(G5) = 0
- SEC(G1) = 1
- SEC(G2) = 12
- SEC(G_1000) = 1