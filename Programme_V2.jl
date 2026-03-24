# Membres : 
# Grace SILVA AND Sandra OUBAKOUK  - M1 ISD - Projet modele matrixhématrixique 2025-2026

using JuMP
using Cbc
using Random
import MathOptInterface as MOI


#******************************************************
# Résultats trouvés pour les graphes G1,G2,G3,G4,G5 : 
# SEC(G3)=2   => [(1,2), (1,3)]                                      
# SEC(G5)=0   => []                                      
# SEC(G4)=2   => [(1,2), (1,3)]                                  
# SEC(G2)=12  => [(20, 10), (12, 10), (24, 10), (17, 10), (6, 10), (11, 10), (9, 10), (3, 10), (13, 10), (15, 10), (18, 10), (26, 10)]                                     
# SEC(G1)=2   => [(25, 1)]                                   
#*******************************************************
#******************************************************
# Résultat de la question 4 : 
# SEC(G_1000) = 1
# Couple critique = (3, 4)
# Arêtes minimales à supprimer = [(3, 4)]
# Temps de calcul = 67.46 sec
#******************************************************


# Question 1
# Calcule du nombre maximal de chemins edge-disjoint allant de a vers b dans G 
# Revient à résoudre un problème de flot maximal 

function P(G, a, b)
    #nombre de sommet du graphe
    n = size(G, 1) 
    #on crée le model d'optimisation
    model = Model(Cbc.Optimizer)
    #on désactive les messages de solveur ça va nous evite des affichages 
    #meme si ça n'empeche pas les messages de log d'apparaitre
    set_silent(model) 
    # On demande à Cbc de ne rien affciher 
    set_attribute(model, "logLevel", 0)

    #variable de flot f[i,j]
    #création de la variable que si l'arc existe dans la matrixrice d'adjacence du graphe
    @variable(model,0<=f[i=1:n, j=1:n; G[i,j] == 1]<=1)

    # valeur totale du flot de a vers b 
    @variable(model,F>=0) 
     
    #contraintes de conservation du flot
    #(nb flot entrant = nb flot sortant )
    #sur tous sommets différents de a et b 
    for i in 1:n
        if i != a && i != b
            @constraint(model, 
                sum(f[j, i] for j in 1:n if G[j, i]==1) == sum(f[i, k] for k in 1:n if G[i, k]==1))
        end
    end

    # flot sortant - flot entrant = F 
    @constraint(model,
        sum(f[a,j] for j in 1:n if G[a,j] == 1) - sum(f[j,a] for j in 1:n if G[j,a] == 1) == F )

    # flot entrant - flot sortant = F 
    @constraint(model, sum(f[j,b] for j in 1:n if G[j,b] == 1) - sum(f[b,j] for j in 1:n if G[b,j] == 1) == F )


    # objectif : maximiser la valeur totale du flot
    @objective(model, Max, F)

    optimize!(model)

    # Retourner la valeur optimal si elle existe sinon erreur 
    if termination_status(model) != MOI.OPTIMAL
        error("OUPSI! Pas de solution optimale")
    end

    return round(Int, value(F))
end

#***********************************
# Test de la fonction P sur G3  : 

# G3 = [
#     0 1 1 0;  #sommet1
#     0 0 1 1;  #sommet2
#     1 0 0 1;  #sommet3
#     1 1 0 0   #sommet4
# ]

#sommet 3 vers sommet 1 
# valeur_G3 = P(G3,3,1) 
# println("Test G3 : ")
# println("P(3,1) =  ", valeur_G3)
#************************************



# Question 2 : 
# Calcul de la SEC  
# SEC(G) = min P(vi, vi+1)
# Algo basique du min 

function calculer_SEC(G)
    n = size(G, 1)
    sec_min = typemax(Int)

    for i in 1:n
        source = i
        cible = (i % n) + 1

        val = P(G, source, cible)

        if val < sec_min
            sec_min = val
        end
    end

    return sec_min
end

#************************************
# Test de la fonction P sur G3  : 

# res_G3 = calculer_SEC(G3)
# println("SEC(G3) = ", res_G3)
#************************************



#Question 3
# Déterminer un ensemble minimal d'arêtes à supprimer 
#correspondant à une coupe minimale

# Retourne la SEC et un couple ou le minimum a été trouvé
# Reprend le même principe que la question 2
function calculer_SEC_avec_couple(G)
    n = size(G, 1)
    sec_min = typemax(Int)
    source_min = 0
    cible_min = 0
    for i in 1:n
        source = i
        cible = (i % n) + 1
        val = P(G, source, cible)
        if val < sec_min
            sec_min = val
            source_min = source
            cible_min = cible
        end
    end
    return sec_min, source_min, cible_min
end

#On a cherché le couple qui donne le minimum 
#Puis on calcule la coupe minimale
#Donne les aretes qu'on doit supprimer
function P_coupe(G, a, b)
    n = size(G, 1)
    model = Model(Cbc.Optimizer) 
    set_silent(model) #même avec ça on voit quand même les logs
    set_attribute(model, "logLevel", 0)

    # Variables de flot sur les arcs existants
    @variable(model, 0 <= f[i=1:n, j=1:n; G[i,j] == 1] <= 1)

    # Valeur totale du flot
    @variable(model, F >= 0)

    # Conservation du flot sur les sommets intermédiaires
    for i in 1:n
        if i != a && i != b
            @constraint(model,
                sum(f[j,i] for j in 1:n if G[j,i] == 1) ==
                sum(f[i,j] for j in 1:n if G[i,j] == 1)
            )
        end
    end
    # Source a : flot net sortant = F
    @constraint(model,
        sum(f[a,j] for j in 1:n if G[a,j] == 1) -
        sum(f[j,a] for j in 1:n if G[j,a] == 1) == F
    )

    # Puits b : flot net entrant = F
    @constraint(model,
        sum(f[j,b] for j in 1:n if G[j,b] == 1) -
        sum(f[b,j] for j in 1:n if G[b,j] == 1) == F
    )

    # Objectif : maximiser le flot total
    @objective(model, Max, F)

    optimize!(model)

    if termination_status(model) != MOI.OPTIMAL
        error("Le solveur n'a pas trouvé de solution optimale.")
    end

    val = round(Int, value(F))
    
    # Sommets atteignables depuis a dans le graphe résiduel
    atteignables = Set([a])
    file = [a]

    while !isempty(file)
        u = popfirst!(file)

        for v in 1:n
            # Arc avant résiduel : u -> v existe et n'est pas saturé
            if G[u,v] == 1 && value(f[u,v]) < 0.999 && !(v in atteignables)
                push!(atteignables, v)
                push!(file, v)
            end

            # Arc arrière résiduel : v -> u existe et porte un flot positif
            if G[v,u] == 1 && value(f[v,u]) > 0.001 && !(v in atteignables)
                push!(atteignables, v)
                push!(file, v)
            end
        end
    end

    # Arêtes de la coupe minimale :
    # arcs allant d'un sommet atteignable vers un sommet non atteignable
    arcs_minimaux = Tuple{Int,Int}[]

    for i in atteignables
        for j in 1:n
            if G[i,j] == 1 && !(j in atteignables)
                push!(arcs_minimaux, (i,j))
            end
        end
    end
    return val, arcs_minimaux
end
    

# Détermine la SEC et l'ensemble minimal d'arêtes à supprimer
# Retourne :
# la SEC / le couple critique (a,b) / l'ensemble minimal d'arêtes à supprimer

function question_3(G)
    sec, a, b = calculer_SEC_avec_couple(G)
    val, arcs = P_coupe(G, a, b)

    return sec, a, b, arcs
end

#*************************************************************
#Test avec G3 entre 3 et 1
#SEC_G3, a_G3, b_G3, coupe_G3 = question_3(G3)
# println("SEC(G3) = ", SEC_G3)
# println("Aretes min à supprimer = ", coupe_G3)
#*************************************************************


# Question 4
# Génère un graphe orienté de 1000 sommets fortement connexe
# puis calcule sa SEC

# Question 4
# Génère un graphe orienté de 1000 sommets fortement connexe,
# calcule sa SEC, puis affiche aussi le couple critique
# et les arêtes minimales à supprimer

function question_4()
    n = 1000
    G_1000 = zeros(Int, n, n)
    # Pour obtenir toujours le même graphe aléatoire
    Random.seed!(1234)
    # On crée un cycle orienté passant par tous les sommets
    # Cela garantit que le graphe est fortement connexe
    for i in 1:n
        suivant = (i % n) + 1
        G_1000[i, suivant] = 1
    end

    # On ajoute 2 arcs aléatoires sortants par sommet
    for i in 1:n
        nb_ajoutes = 0
        while nb_ajoutes < 2
            cible = rand(1:n)

            # On évite les boucles et les doublons
            if cible != i && G_1000[i, cible] == 0
                G_1000[i, cible] = 1
                nb_ajoutes += 1
            end
        end
    end

    println("Calcul de la SEC du graphe de 1000 sommets...")

    time_start = time()

    # On récupère la SEC et le couple critique
    sec_1000, a_1000, b_1000 = calculer_SEC_avec_couple(G_1000)

    # On calcule la coupe minimale associée
    val_1000, arcs_1000 = P_coupe(G_1000, a_1000, b_1000)

    duration = time() - time_start

    println("******************************************")
    println("RÉSULTAT QUESTION 4 : ")
    println("SEC(G_1000) = ", sec_1000)
    println("Couple donnat le min = (", a_1000, ", ", b_1000, ")")
    println("Arêtes minimales à supprimer = ", arcs_1000)
    println("Temps de calcul = ", round(duration, digits = 2), " sec")

    return G_1000, sec_1000, a_1000, b_1000, arcs_1000
end

# Test Question 4 :
# On décommente cette ligne si on veut tester la question 4
#question_4()


#***********************************************************************
# TESTS AVEC LES AUTRES GRAPHES :
#***********************************************************************

G3 = [
    0 1 1 0; # 1 
    0 0 1 1; # 2 
    1 0 0 1; # 3 
    1 1 0 0  # 4 
]
G4 = [
    0 1 1 0 0 0 0; # 1
    0 0 1 1 1 0 0; # 2
    1 0 0 1 1 1 0; # 3
    1 1 0 0 0 0 1; # 4
    0 0 0 0 0 1 1; # 5
    0 0 1 0 0 0 1; # 6
    0 0 1 0 1 0 0  # 7
]
G5 =[
    0 1 1 1 0 1 0 0 0 0 0 0  ; #alpha
    0 0 1 0 1 0 0 0 0 0 0 0  ; #a
    0 0 0 0 0 0 0 0 1 0 0 0  ; #b    
    0 0 1 0 0 1 0 0 1 0 0 0  ; #c
    0 0 0 0 0 0 0 0 0 1 0 0  ; #d
    0 0 0 0 0 0 0 1 1 0 0 0  ; #e
    0 0 0 0 0 0 0 0 0 0 1 1  ; #f
    0 0 0 0 0 0 1 0 1 0 0 1  ; #g
    0 0 0 0 1 0 1 0 0 0 0 0  ; #h
    0 1 0 0 0 0 1 0 0 0 1 1  ; #i
    0 0 0 0 0 0 0 0 0 0 0 1  ; #j
    0 0 0 0 0 0 0 0 0 0 0 0   #beta
    
]

G1= [
    0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0;
    0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0;
    0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0;
    0 1 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0;
    0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0;
    0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0;
    0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 0 0 0;
    0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 1 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 1 0 1 0 1 0 0 0 0 0 1 1 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 1 1 0 1 1 0 0 0 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 0 0 1 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 1 1 1 0 0 0 0 0 0 0 0;
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1;
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 1 0 0 0 0 0 0 0 1;
    0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 0 0 0 0 1 0 0;
    0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 0 1 0 0 0;
    0 0 0 0 0 0 1 1 1 0 0 0 0 0 0 0 0 0 0 0 1 0 1 0 0 0;
    0 0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0;
    0 0 0 1 0 1 0 0 0 0 0 0 0 0 0 0 0 0 1 1 0 0 1 0 0 0;
    0 0 1 0 0 0 0 0 0 0 0 0 0 1 0 0 0 1 1 0 0 0 0 0 0 0;
    0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 1 0 1 0;
    1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 1;
    0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 1 1 0

]

G2=[
    0 1 1 0 1 1 0 0 1 0 0 1 0 1 0 1 0 1 1 0 1 0 0 1 0 1;
    1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 1 0 1 0 1 0 1 0 1;
    1 1 0 1 0 1 1 0 1 1 0 1 0 1 0 1 0 0 1 0 1 0 1 0 0 0;
    0 0 1 0 1 1 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0;
    0 1 0 1 0 1 0 1 1 0 1 0 1 0 1 1 0 1 1 0 1 0 1 0 1 0;
    0 1 0 1 1 0 1 0 1 1 0 1 1 0 1 1 1 0 1 1 0 1 1 0 1 0;
    1 0 1 0 1 1 0 1 1 0 1 1 0 1 0 1 1 0 1 1 0 1 1 0 1 1;
    1 0 1 1 0 1 1 0 1 0 1 1 0 1 1 0 1 1 0 1 0 1 1 1 0 1;
    0 1 1 0 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 1 0 1 1 0 1;
    1 1 1 0 1 1 0 1 1 0 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 1;
    1 0 1 1 0 1 0 1 1 1 0 1 1 0 1 0 1 1 0 1 0 1 1 0 1 1;
    0 1 0 1 1 0 1 1 0 1 1 0 1 1 1 0 1 1 0 1 1 0 1 1 1 0;
    1 0 1 0 1 1 0 1 0 1 1 1 0 1 1 0 1 1 1 0 1 1 0 1 0 1;
    1 1 0 1 0 1 1 0 1 0 1 1 0 0 1 1 0 1 1 0 1 1 0 1 1 0;
    0 1 0 1 0 1 0 1 1 1 0 1 1 1 0 1 1 0 1 1 0 1 1 0 0 1;
    1 0 1 0 1 0 1 0 0 0 1 0 1 1 1 0 1 1 0 1 0 1 1 0 1 0;
    1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 0 1 0 1 0 1 1 0 1 1;
    0 0 1 1 0 1 0 1 0 1 0 1 1 0 1 1 1 0 1 1 0 1 1 0 1 0;
    0 1 0 1 0 1 0 1 1 0 1 0 1 1 0 1 1 1 0 0 0 1 0 1 1 0;
    0 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 0 1 0 1 0 1 0;
    1 0 1 0 1 1 0 1 1 0 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 0;
    1 0 1 0 1 1 0 1 1 0 1 1 0 1 1 0 1 1 1 0 1 0 1 1 0 1;
    0 0 1 0 1 0 1 0 1 0 1 1 1 0 1 1 0 1 1 0 1 1 0 1 0 1;
    0 1 0 0 1 0 1 1 0 1 0 1 1 0 1 0 1 1 0 1 0 1 1 0 1 0;
    1 1 0 1 0 1 1 0 1 0 1 1 0 1 1 0 1 0 1 0 1 1 0 1 0 1;
    0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 1 0
]


function executer_tests()
    vals_G = [
        (G3, "G3"),
        (G4, "G4"),
        (G5, "G5"),
        (G1, "G1"),
        (G2, "G2")
    ]

    println("TEST DES GRAPHES")

    for (matrix, nom) in vals_G
        println()
        println("******************************************")
        println("Graphe : ", nom)
        sec = calculer_SEC(matrix)
        println("SEC(", nom, ") = ", sec)

        sec2, a, b, arcs = question_3(matrix)
        println("Couple donnant le min = (", a, ", ", b, ")")
        println("Arêtes minimales à delete = ", arcs)
        if sec != sec2
            println("incohérence !")
        end

        if length(arcs) != sec
            println("nb d'arêtes trouvées n'est pas égal à la SEC")
        end
    end

    println()
    println("******************************************")
    println("RÉCAPITULATIF FINAL DES 4 vals_G")

    sec_G3, a_G3, b_G3, arcs_G3 = question_3(G3)
    println("G3 : SEC(G3) = ", sec_G3,
            " ; couple critique = (", a_G3, ", ", b_G3, ")",
            " ; arêtes à supprimer = ", arcs_G3)

    sec_G4, a_G4, b_G4, arcs_G4 = question_3(G4)
    println("G4 : SEC(G4) = ", sec_G4,
            " ; couple critique = (", a_G4, ", ", b_G4, ")",
            " ; arêtes à supprimer = ", arcs_G4)

    sec_G5, a_G5, b_G5, arcs_G5 = question_3(G5)
    println("G5 : SEC(G5) = ", sec_G5,
            " ; couple critique = (", a_G5, ", ", b_G5, ")",
            " ; arêtes à supprimer = ", arcs_G5)

    sec_G1, a_G1, b_G1, arcs_G1 = question_3(G1)
    println("G1 : SEC(G1) = ", sec_G1,
            " ; couple critique = (", a_G1, ", ", b_G1, ")",
            " ; arêtes à supprimer = ", arcs_G1)

    sec_G2, a_G2, b_G2, arcs_G2 = question_3(G2)
    println("G2 : SEC(G2) = ", sec_G2,
            " ; couple critique = (", a_G2, ", ", b_G2, ")",
            " ; arêtes à supprimer = ", arcs_G2)
end

#**********************************************************
# Lancement des tests
#**********************************************************

executer_tests()