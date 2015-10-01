KV
==

Au démarrage :

Le module `KV` — qui implémente `Application` — démarre un `KV.Supervisor`.

Lors de son initialisation `KV.Supervisor` démarre la supervision de 3 enfants (en stratégie `:one_for_one`) :

1. un worker `GenEvent` nommé `KV.EventManager` ;
2. un superviseur `KV.Bucket.Supervisor` ;
3. un worker `KV.Registry` avec les 2 précédents en paramètres.


`KV.Bucket.Supervisor` a la responsabilité de la gestion des buckets (ensembles de données de type clé/valeur). Chaque bucket est un nouvel enfant. Vu que la stratégie ets `:simple_one_for_one` la création d'un nouvel enfant va se calquer sur la définition de l'enfant faite à l'initialisation du superviseur. Cet enfant initial ne sert en fait à rien, juste à définir la supervision et le modèle des futurs enfants. S'il meurt il ne sera pas redémarré (`restart: :temporary`).

`KV.Bucket` a la responsabilité des opérations de lecture/écriture dans un lot de données. Ces opérations sont faites via un `Agent` afin de conserver l'état des données accessible. Au démarrage l'Agent indique son "pid". À chaque opération, on indique le pid de l'agent à utiliser et la fonction et les paramètres passés sont alors utilisés dans le contexte de cet processus.

`KV.Registry` a la responsibilité de la facade de fonctionnalités (`:create` et `:lookup`). C'est un `GenServer`, il fonctionne dans son propre processus. En tant que registre il connaît tous les buckets disponibles.
Dans un `names` il conserve la correspondance entre le nom d'un bucket et son pid.
Dans `refs` il conserve la correspondance entre une référence de "monitoring" et le nom du bucket.
Pour les méthodes asynchrones (création d'un bucket) il transmet la demande à `KV.Bucket.Supervisor` qui renvoi un pid. Ce pid sert à démarre un monitoring. Il ajoute la référence et le nom du bucket dans les structures adéquates (`refs` et `names`). Il transmet une notification de création au gestionnaire d'évènements.
Lorsqu'il est notifié du plantage d'un processus, il supprimes les données de correspondance, notifie le gestionnaire d'évènements et renvoi l'état modifié.