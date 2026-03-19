#Grace SILVA & Sandra OUBAKOUK M1 ISD 
using JuMP
using Cbc
using Random

# sec(g3)=2
# sec(g5)=0
# sec(g4)=2
# sec(g2)=13
# sec(g1)=2






# Question 1
function P(G, a, b)
    #nombre de sommet du graphe
    n = size(G, 1) 
    model = Model(Cbc.Optimizer)
    set_silent(model) 

    #variable de flot f[i,j]
    #création de la variable que si l'arc existe dans la matrice d'adjacence du graphe
    @variable(model,0<=f[i=1:n, j=1:n; G[i,j] == 1]<=1)

    #Le but est de maximiser le flot sortant du premier sommet 
    @objective(model,Max,sum(f[a, j] for j in 1:n if G[a, j]==1))

    #contraintes de conservation du flot , (nb flot entrant = nb flot sortant )
    for i in 1:n
        if i != a && i != b
            @constraint(model, 
                sum(f[j, i] for j in 1:n if G[j, i]==1) == sum(f[i, k] for k in 1:n if G[i, k]==1))
        end
    end
    optimize!(model)
    return objective_value(model)
end

#petit test avec G3 entre 1 et 3
G3 = [
    0 1 1 0; # 1 
    0 0 1 1; # 2 
    1 0 0 1; # 3 
    1 1 0 0  # 4 
]

valeurG3= P(G3, 3, 1)
println("Le flot max P(3, 1) pour G3 est: ", valeurG3)

#Question 2 
# Question 2 : Calcul de la SEC avec la règle v_n = v_0
function calculer_SEC(G)
    n = size(G, 1)
    sec_min = Inf 
    
    # L'énoncé suggère v0, v1... vn-1 
    # Pour s'assurer de tester la structure circulaire complète :
    for i in 1:n
        source = i
        # Si i = n, cible = 1 (retour au départ) 
        cible = (i % n) + 1 
        
        val = P(G, source, cible)
        
        # Si on trouve un 0, le graphe n'est pas fortement connecté 
        if val < sec_min
            sec_min = val
        end
        
        # Astuce de debug pour G5 :
        if val == 0
            println("Coupure détectée entre $source et $cible")
        end
    end
    
    return sec_min
end
#test sur G3
resultat= calculer_SEC(G3)
println("La SEC du graphe G3 est: ", resultat)


#Question 3
function P_coupe(G, a, b)
    n = size(G, 1)
    model = Model(Cbc.Optimizer)
    set_silent(model)
    @variable(model, 0 <= f[i=1:n, j=1:n; G[i,j] == 1] <= 1)
    @objective(model, Max, sum(f[a, j] for j in 1:n if G[a, j] == 1))
    
    for i in 1:n
        if i != a && i != b
            @constraint(model, 
                sum(f[j, i] for j in 1:n if G[j, i]==1) == sum(f[i, k] for k in 1:n if G[i, k]==1)
            )
        end
    end
    
    optimize!(model)
    val= objective_value(model)

    #les sommets atteignables depuis a avec le flot actuel
    atteignables = [a]
    file = [a]
    while !isempty(file)
        u = popfirst!(file)
        for v in 1:n
            #sommet est atteignable si l'arc n'est pas saturé (flot < 1)
            if G[u, v] == 1 && value(f[u, v]) < 0.99 && !(v in atteignables)
                push!(atteignables, v)
                push!(file, v)
            end
        end
    end
    #arcs_minimaux: arcs qui partent d'un sommet atteignable vers un sommet non-atteignable
    arcs_minimaux = []
    for i in atteignables
        for j in 1:n
            if G[i, j] == 1 && !(j in atteignables)
                push!(arcs_minimaux, (i, j))
            end 
        end
    end
    
    return val, arcs_minimaux
end
    

#test avec G3 entre 3 et 1
flot, liste_arcs = P_coupe(G3, 3, 1)

println("Valeur du flot P(3, 1) : ", flot)
println("Ensemble minimal d'arcs à supprimer : ", liste_arcs)


#Question 4 
function question_4()
    n = 1000
    G_1000 = zeros(Int, n, n)
    println("Génération du graphe")
    
    #cycle pour garantir la forte connexité 
    for i in 1:n
        suivant = (i % n) + 1
        G_1000[i, suivant] = 1
    end
    
    #arcs aléatoires pour complexifier le graphe
    for i in 1:n
        for _ in 1:2
            cible = rand(1:n)
            if cible != i
                G_1000[i, cible] = 1
            end
        end
    end
    
    # Chronométrer le calcul
    time_start = time()
    sec_1000 = calculer_SEC(G_1000)
    duration = time() - time_start
    
    println("RESULTAT QUESTION 4 ")
    println("SEC du graphe de 1000 sommets : ", sec_1000)
    println("Temps de calcul : ", round(duration, digits=2), " secondes")
end


# test avec les autres graphe 


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

function executer()
    instances = [(G3, "G3"), (G4, "G4"), (G5, "G5"), (G1, "G1"), (G2, "G2")]
    
    for (mat, nom) in instances
        println("\nGraphe: $nom")
        sec = calculer_SEC(mat)
        println("RÉSULTAT FINAL : SEC($nom) = $sec")
        
        v_flot, arcs = P_coupe(mat, 1, 2)
        println("Exemple de coupe min entre 1 et 2 : $arcs (valeur: $v_flot)")
        
    end
end

# Lancement des tests
executer()

# test question 4 aprés les autres car plus long
question_4()


#récap


println("SOLUTIONS DES GRAPHES :")
println("SEC(G3) = ", calculer_SEC(G3))
println("SEC(G4) = ", calculer_SEC(G4))
println("SEC(G5) = ", calculer_SEC(G5))
println("SEC(G1) = ", calculer_SEC(G1))
println("SEC(G2) = ", calculer_SEC(G2))