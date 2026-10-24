# Feuille de route de migration

## Objectif et périmètre

Ce dépôt est Spring Petclinic : un monolithe pédagogique de gestion de clinique vétérinaire, pas une application bancaire. Il ne contient pas de comptes bancaires, de transactions financières ni de grand livre. Le projet peut servir à apprendre les mécanismes de migration progressive, mais toute analogie bancaire devra être explicitement présentée comme telle et ne devra pas être prise pour une fonction existante.

Le principe directeur est de conserver le monolithe fonctionnel, de mesurer son comportement de référence, puis d’extraire un seul domaine réellement présent à la fois. Aucune extraction, double écriture ou migration de données ne doit commencer avant la validation du comportement de référence et du périmètre choisi.

## État actuel

- L’application monolithique intacte s’exécute sur Minikube avec PostgreSQL.
- La suite Maven a réussi : 81 tests exécutés, 0 échec, 0 test ignoré lors du dernier build d’image.
- Les pods Petclinic et PostgreSQL étaient `Ready`; le PVC PostgreSQL de 1 Gio était `Bound`.
- L’interface web intégrée (Thymeleaf) a été vérifiée sur `http://localhost:8081/` via `kubectl port-forward`.
- Les manifestes Minikube ont été adaptés pour l’image locale, les paramètres PostgreSQL et un PVC. Le Dockerfile local construit l’image à partir du JAR.
- Le port-forward est temporaire et doit rester actif pour conserver l’accès sur `localhost:8081`.
- Les étapes ci-dessous ne sont pas considérées comme terminées simplement parce que le cluster fonctionne : les parcours de référence, les mesures et les décisions d’architecture restent à documenter.

## Principes de sécurité et de migration

- Utiliser uniquement les données synthétiques fournies par l’application. Ne pas y placer de véritables données personnelles, identifiants, paiements ou opérations financières.
- Garder le monolithe déployable et prévoir un retour de routage vers celui-ci.
- Définir un propriétaire unique pour chaque donnée. Un nouveau service ne doit pas écrire directement dans les tables dont le monolithe reste propriétaire.
- Ne jamais exécuter deux fois une commande qui produit un effet de bord. Un Parallel Run peut comparer des lectures ou calculs déterministes ; il ne doit pas dupliquer une création, une réservation ou une autre écriture.
- Préférer d’abord les changements réversibles et observables. CDC et dual-write restent différés jusqu’à la définition de l’idempotence, des reprises et de la réconciliation.

## Étapes

### 1. Stabiliser et documenter la référence monolithique

Actions :

- Consigner le commit Git, les versions Java/Spring Boot, la commande Maven, le profil actif, la base utilisée et les paramètres Minikube.
- Rejouer `./mvnw test` avant toute expérimentation et archiver le résumé du build.
- Définir quelques parcours répétables avec données synthétiques : page d’accueil, recherche et affichage d’un propriétaire, affichage des vétérinaires, création ou mise à jour d’un animal, ajout d’une visite.
- Pour chaque parcours, relever résultat attendu/réel, code HTTP ou résultat UI, erreurs, durée approximative, logs corrélés et éventuel redémarrage de pod.
- Capturer l’état des pods, services, PVC et ressources au repos. Faire plusieurs mesures avant d’établir une valeur de référence ; noter la méthode et les limites plutôt que de présenter une mesure unique comme un SLO.
- Vérifier un redémarrage de pod et confirmer que PostgreSQL conserve les données sur le PVC.

Critère de sortie : parcours reproductibles documentés, suite de tests verte, démarrage et connexion PostgreSQL vérifiés, limites de la mesure explicitées.

### 2. Cartographier les domaines et choisir une seule extraction

Candidats observés dans le code :

- `vet` : vétérinaires et spécialités. Domaine relativement indépendant, avec une liste JSON sur `/vets`; bon candidat technique de faible risque, principalement en lecture.
- `owner` : propriétaires et recherche. Les contrôleurs chargent et enregistrent des agrégats qui contiennent également les animaux ; séparation moins autonome qu’elle n’en a l’air.
- `pet` : animaux et types d’animaux. Les animaux sont rattachés aux propriétaires ; les types sont référencés lors de leur édition.
- `visit` : visites associées à un animal et enregistrées en passant par le propriétaire. Parcours d’écriture utile, mais fortement couplé au modèle propriétaire-animal.

Avant de choisir, établir pour le candidat : endpoints concernés, classes, tables, clés étrangères, lectures/écritures, validations, vues qui en dépendent, tests disponibles, comportement en cas de panne et stratégie de retour arrière.

Critère de sortie : un seul domaine limité est choisi, avec données possédées, contrat externe, dépendances et risques approuvés. Ne pas commencer par extraire plusieurs domaines simultanément.

### 3. Préparer la cible et un routage réversible

- Garder le monolithe et sa route actuelle opérationnels.
- Définir une passerelle devant le monolithe, avec une route par défaut vers le monolithe et une route explicitement sélectionnée pour le domaine choisi.
- Décrire comment désactiver cette route et rétablir le routage vers le monolithe sans redéploiement risqué.
- Définir les contrats HTTP, les erreurs, les délais d’attente, les limites de reprise et la compatibilité des réponses.
- Ajouter une corrélation de requête commune aux journaux de la passerelle, du monolithe et du nouveau service.

Critère de sortie : le trafic peut être renvoyé au monolithe et cette procédure est testée avant toute bascule réelle.

### 4. Extraire un service sans déplacer la propriété des données trop tôt

- Créer un service Spring Boot autonome pour le domaine validé, avec tests unitaires et tests d’intégration ciblés.
- Commencer avec un contrat explicite et une persistance isolée ou une lecture contrôlée ; ne pas partager implicitement les entités JPA ni laisser le service modifier librement les tables du monolithe.
- Préparer des données synthétiques de test et un test de compatibilité du contrat.
- Déployer une instance du service sans lui envoyer de trafic utilisateur, vérifier ses sondes, ses logs et son accès aux dépendances.

Critère de sortie : service déployé et vérifiable indépendamment, contrat couvert par des tests, responsabilité des données écrite noir sur blanc.

### 5. Basculer progressivement avec Strangler Fig

- Garder la route monolithe comme comportement par défaut.
- Router un parcours borné vers le nouveau service par configuration ou règle de passerelle réversible.
- Vérifier d’abord le parcours synthétique, puis augmenter progressivement le trafic si les résultats et les métriques restent conformes.
- Suivre taux d’erreur, latence, disponibilité, saturation, logs et différences fonctionnelles.
- Déclencher le retour au monolithe si le service est indisponible ou si les résultats s’écartent des critères définis.

Parallel Run : l’utiliser seulement lorsque la seconde exécution est sans effet de bord (par exemple, comparaison de lectures ou de calculs déterministes). Pour les écritures, ne pas envoyer la même commande aux deux côtés. Une comparaison d’écriture ne sera envisagée qu’avec une stratégie d’idempotence et sans double exécution de l’opération métier.

Critère de sortie : trafic progressif contrôlé, comparaison documentée, retour arrière essayé, aucun effet de bord dupliqué.

### 6. Traiter les données et la cohérence après la première extraction

Avant CDC ou dual-write :

- nommer le système propriétaire de chaque table ou agrégat et interdire les écritures concurrentes non coordonnées ;
- définir une clé d’idempotence stable et son stockage/durée de conservation ;
- décrire les reprises, les événements en retard ou en double, l’ordre, les erreurs permanentes et le rejeu ;
- définir une réconciliation périodique et les seuils d’écart acceptables ;
- tester les pannes entre l’écriture source et la propagation, ainsi que le retour arrière.

Préférer une migration par étapes avec période de lecture seule ou transfert explicite de propriété lorsque cela suffit. N’activer CDC ou dual-write qu’après validation de ces scénarios et de tests de panne.

Critère de sortie : propriétaire, idempotence, reprises et réconciliation sont documentés et testés avant le changement du chemin d’écriture.

### 7. Durcir le déploiement Kubernetes

- Conserver PostgreSQL avec PVC pour l’environnement pédagogique ; vérifier sauvegarde/restauration si les données doivent survivre à une perte du cluster.
- Utiliser des Secrets pour les identifiants et éviter les mots de passe réels ou partagés dans un manifeste versionné.
- Définir des demandes et limites CPU/mémoire adaptées aux mesures.
- Maintenir les sondes de démarrage, readiness et liveness ; vérifier qu’elles reflètent respectivement l’initialisation, la capacité à recevoir du trafic et le blocage du processus.
- N’introduire un HPA que lorsque des métriques de ressources sont disponibles et que les limites, requests et comportement sous charge sont mesurés.
- Définir des tags d’image reproductibles et une méthode de mise à jour/retour arrière.

Critère de sortie : chaque composant dispose de ressources et sondes cohérentes, le déploiement et le rollback sont reproductibles.

### 8. Ajouter l’observabilité progressivement

- Standardiser les logs structurés, horodatés et corrélables ; centraliser ensuite les logs avec EFK si le besoin pédagogique le justifie.
- Exposer des métriques utiles : requêtes, latence, erreurs, saturation JVM, pool JDBC, disponibilité des dépendances et état des sondes.
- Ajouter Prometheus et Grafana pour collecte et tableaux de bord, puis Alertmanager avec quelques alertes actionnables.
- Définir les indicateurs et seuils à partir de la référence, sans considérer une pile d’observabilité comme preuve de fiabilité à elle seule.
- Restreindre les endpoints Actuator : la configuration actuelle expose tous les endpoints et ne doit pas être conservée telle quelle hors laboratoire local contrôlé.

Critère de sortie : une requête peut être suivie entre passerelle et services, les erreurs et latences sont visibles, les alertes sont testées et les endpoints d’administration sont limités.

## Ordre recommandé

1. Référence monolithique et scénarios de test.
2. Cartographie des dépendances et choix d’un domaine.
3. Passerelle avec retour arrière vérifié.
4. Un service extrait, sans double écriture.
5. Bascule progressive et comparaison sûre.
6. Propriété et migration des données ; CDC/dual-write seulement si nécessaires.
7. Durcissement Kubernetes et autoscaling mesuré.
8. Centralisation EFK et métriques Prometheus/Grafana/Alertmanager.

## Hors périmètre de la première étape

Ne pas commencer par une extraction, un HPA, EFK, CDC, dual-write, une refonte du front-end ou une réécriture complète. Le premier jalon est une référence monolithique mesurée et reproductible.