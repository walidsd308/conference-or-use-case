# Explication détaillée de la méthode `choose_patients`

## 1. Vue d'ensemble

La fonction `choose_patients()` est un processus **interactif et itératif** qui affecte des patients à des créneaux horaires spécifiques dans des salles d'opération. Elle transforme une liste de propositions d'ordonnancement automatique en un calendrier final validé par l'utilisateur.

### Entrées
- `data` : Dictionnaire contenant les données du système (patients, médecins, blocs opératoires, planifications)
- `chosen_events` : Dictionnaire vide (sera rempli au fur et à mesure) → format: `{(physician_id, patient_id): (day, bloc_id, index, event_id)}`
- `final_result` : Propositions initiales de l'algorithme d'ordonnancement → format: `{(physician_id, patient_id): [(day, bloc_id, index, event_id), ...]}`
- `deleted_patients_ids` : Liste des patients à supprimer si leurs créneaux sont sélectionnés

### Sortie
- `chosen_events` : Dictionnaire complété avec les choix finaux de l'utilisateur

---

## 2. Processus détaillé

### Phase 1 : Initialisation
```
1. Initialiser chosen_events comme dictionnaire vide
2. Extraire les données essentielles :
   - blocs_days_informations : Informations sur les créneaux disponibles par bloc et jour
   - physicians : Liste des médecins
   - patients : Liste des patients
   - physicians_plannings : Agenda des médecins
```

### Phase 2 : Boucle itérative principale
**Condition de sortie** : `len(chosen_events) >= len(final_result)`
(Tous les patients doivent avoir un créneau assigné)

#### Itération N :

**Étape 1 : Identifier le meilleur patient à traiter**
```
Fonction: patients_order_getter(scheduling_events, data, chosen_events)
```

Cette fonction effectue :
1. **Filtrage des événements non choisis** :
   - Supprime les entrées déjà assignées
   - Identifie les alternatives rejetées par l'utilisateur

2. **Recalcul de la disponibilité des blocs** :
   - Fonction `get_updates_blocs_available_time()`
   - Recalcule le temps disponible après chaque sélection
   - Prend en compte : durée opératoire + récupération post-opératoire

3. **Mise à jour des événements possibles** :
   - Fonction `updated_events_with_no_chosen_event()`
   - Pour chaque patient non assigné, vérifie si les créneaux rejetés deviennent disponibles
   - Valide les contraintes de compatibilité :
     - ✓ Médecin disponible à ce bloc/jour
     - ✓ Patient pas déjà assigné dans ce créneau
     - ✓ Pas de conflit jour/bloc
     - ✓ Patient dans sa fenêtre de disponibilité (arrival_date → departure_date)
     - ✓ Temps disponible suffisant dans le bloc

4. **Calcul du score de chaque patient** :
   - Fonction `get_score_of_patient()`
   - Métrique principale : **score d'arrivée/départ**
     - `+100` si le jour est entre arrival_date et departure_date (optimal)
     - `-|jour - arrival_date|` si jour < arrival_date
     - `-|jour - departure_date|` si jour > departure_date
   - Le score total est la somme des scores de tous les créneaux possibles

5. **Sélection du meilleur patient** :
   - `best_key = max(patients_score, key=patients_score.get)`
   - Sélectionne le patient avec le score total le plus élevé

6. **Tri des propositions** :
   - Fonction `sort_events()`
   - Trie les créneaux par score décroissant
   - Affiche d'abord les créneaux les plus favorables

**Retour** : `(best_key, sorted_events)`

**Étape 2 : Affichage des propositions à l'utilisateur**
```
Afficher :
- Nom du patient sélectionné
- Nom du médecin responsable
- Liste numérotée des créneaux proposés :
  - Format : "Index: jour Day bloc_name"
  - Exemple : "0: day 2 bloc_name Bloc A"
```

**Étape 3 : Saisie de l'utilisateur**
```
Demander : "Choisir un des créneaux..."
Boucle de validation :
  - Si entrée non entière → réessayer
  - Si indice hors limites → réessayer
  - Si entrée valide → continuer
```

**Étape 4 : Vérification des conflits**
```
Pour le créneau sélectionné (bloc_id, day) :
  Parcourir deleted_patients_ids
  Si une paire (bloc_id, day) correspond :
    Afficher : "this patients will be deleted"
    Pour chaque patient_id concerné :
      Afficher son nom
```

**Étape 5 : Assignation du choix**
```
chosen_events[best_key] = chosen_event
```

### Phase 3 : Finalisation
```
Boucle terminée quand len(chosen_events) == len(final_result)
Afficher : "fin."
Afficher le récapitulatif complet en format table
```

---

## 3. Structures de données clés

### Format des clés patients
```python
(physician_id, patient_id)
# Exemple : (0, 5) = Médecin ID 0, Patient ID 5
```

### Format des créneaux
```python
(day, bloc_id, index, event_id)
# day : numéro du jour (0-based)
# bloc_id : identifiant du bloc opératoire
# index : position du patient dans le bloc ce jour-là
# event_id : identifiant unique de l'événement (IDBASE + position dans scheduling)
```

### Dictionnaire des résultats finaux
```python
chosen_events = {
    (phy_id_1, patient_id_1): (day_1, bloc_id_1, index_1, event_id_1),
    (phy_id_2, patient_id_2): (day_2, bloc_id_2, index_2, event_id_2),
    # ...
}
```

---

## 4. Critères d'ordonnancement et constraints

### Scoring (pour identifier le prochain patient à traiter)
| Condition | Score | Raison |
|-----------|-------|--------|
| Jour dans [arrival_date, departure_date] | +100/créneau | Patient disponible naturellement |
| Jour < arrival_date | -\|jour - arrival_date\| | Repositionnement avant l'arrivée |
| Jour > departure_date | -\|jour - departure_date\| | Repositionnement après le départ |

**Stratégie** : Traiter d'abord les patients avec score total le plus élevé (moins de contraintes temporelles)

### Validation des créneaux disponibles
Un créneau est possible si ET seulement si :
1. ✓ Le médecin est planifié à ce bloc/jour
2. ✓ L'événement n'a pas déjà été choisi
3. ✓ Pas de conflit bloc/jour pour ce patient
4. ✓ Patient dans sa fenêtre de disponibilité (compte tenu du type de repositionnement)
5. ✓ Temps disponible dans le bloc ≥ durée du patient

### Types de repositionnement
```python
patient["Type_of_reprogramming"]
# "before"  : peut être opéré avant sa date d'arrivée
# "after"   : peut être opéré après sa date de départ
# "between" : doit rester dans sa fenêtre [arrival_date, departure_date]
```

---

## 5. Algorithme résumé pour rapport externe

```
ALGORITHME CHOOSE_PATIENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ENTRÉE :
  - final_result : propositions automatiques {(phy, patient): [créneaux...]}
  - data : données système

SORTIE :
  - chosen_events : assignations finales {(phy, patient): créneau}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TANT QUE |chosen_events| < |final_result| FAIRE

  ┌─────────────────────────────────────────────────────────────┐
  │ ÉTAPE 1 : SÉLECTION DU PROCHAIN PATIENT À TRAITER          │
  │                                                             │
  │ Pour chaque (médecin, patient) non assigné :              │
  │   1. Recalculer disponibilité des blocs                   │
  │   2. Identifier créneaux compatibles (validations)        │
  │   3. Calculer score = Σ(score_arrivée_départ)           │
  │ ↓                                                          │
  │ Sélectionner patient avec score maximal                  │
  │ Obtenir : best_patient_key, sorted_time_slots           │
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │ ÉTAPE 2 : INTERACTION UTILISATEUR                          │
  │                                                             │
  │ Afficher :                                                 │
  │   - Nom du patient sélectionné                            │
  │   - Nom du médecin responsable                            │
  │   - Liste des créneaux possibles (triés par score)       │
  │                                                             │
  │ SAISIR : choix = input("Choisir créneau...")            │
  │                                                             │
  │ VALIDER :                                                  │
  │   - Entrée entière ? ✓ Continuer : ✗ Réessayer         │
  │   - Index dans [0, len(créneaux)) ? ✓ Continuer : ✗ Réessayer
  └─────────────────────────────────────────────────────────────┘

  ┌─────────────────────────────────────────────────────────────┐
  │ ÉTAPE 3 : CONFIRMATION ET ASSIGNATION                      │
  │                                                             │
  │ créneau_choisi = sorted_time_slots[choix]                │
  │                                                             │
  │ SI (bloc_id, jour) entraîne suppression d'autres patients :
  │   Afficher liste des patients à supprimer                │
  │                                                             │
  │ chosen_events[best_patient_key] = créneau_choisi        │
  │                                                             │
  │ ↓ Boucle continue                                         │
  └─────────────────────────────────────────────────────────────┘

FIN TANT QUE

RETOURNER chosen_events

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

COMPLEXITÉ
──────────
- Itérations : O(nombre de patients)
- Par itération :
  - Calcul des scores : O(patients × créneaux)
  - Validation : O(créneaux × contraintes)
- Total : O(n² × m) où n = patients, m = créneaux moyens
```

---

## 6. Points clés pour l'implémentation

### Avantages de cette approche
✓ **Flexibilité** : L'utilisateur peut surcharger les propositions automatiques
✓ **Transparence** : Justification via scoring visible pour chaque choix
✓ **Adaptabilité** : Recalcul dynamique des contraintes après chaque assignation
✓ **Contrôle** : Gestion interactive des conflits et suppressions

### Limitations
✗ Processus manuel → scalabilité limitée (centaines de patients)
✗ Pas de marche arrière → pas d'optimisation globale
✗ Dépendant des décisions utilisateur → variabilité des résultats

### Paramètres critiques
| Paramètre | Impact | Valeur typique |
|-----------|--------|----------------|
| Score arrivée/départ | +100 | Priorité maximale |
| Type de repositionnement | Fenêtre valide | Défini par patient |
| Temps post-opératoire | Disponibilité bloc | Depends on intervention |

---

## 7. Cas d'usage et exemples

### Cas nominal
```
Propositions :
  (Médecin 1, Patient A): [(Jour 2, Bloc X), (Jour 3, Bloc Y), (Jour 5, Bloc X)]
  (Médecin 1, Patient B): [(Jour 2, Bloc Y), (Jour 4, Bloc X)]

Itération 1 :
  → Patient avec meilleur score (ex: Patient A, score = 200)
  → Utilisateur choisit : (Jour 3, Bloc Y)
  → chosen_events[(M1, A)] = (3, Y, ...)

Itération 2 :
  → Recalcul : créneaux Patient B réajustés
  → Nouvelle proposition Patient B
  → Utilisateur choisit créneau
```

### Cas avec conflit
```
Utilisateur sélectionne créneau qui provoque suppression :
  → Affiche : "this patients will be deleted"
  → Liste des patients impactés
  → Confirm quand même → suppression exécutée
```

---

## 8. Fluxgramme complet

```
┌─────────────────────┐
│ START               │
│ chosen_events = {}  │
└──────────┬──────────┘
           │
           ▼
    ┌──────────────────────────┐
    │ chosen_events complété ? │
    │ (len == len(final_res))  │
    └──────────┬───────────────┘
               │ NON
               ▼
    ┌──────────────────────────────────────┐
    │ PATIENTS_ORDER_GETTER                │
    │ - Recalcul disponibilités            │
    │ - Validation créneaux                │
    │ - Calcul scores (priorité patient)  │
    │ - Sélection meilleur patient         │
    │ - Tri des créneaux proposés          │
    │ Retour: (best_key, sorted_slots)    │
    └──────────┬───────────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────┐
    │ AFFICHAGE & SAISIE                   │
    │ - Nom patient + médecin              │
    │ - Liste créneaux                     │
    │ - Input utilisateur                  │
    │ - Validation (entier, plage)         │
    └──────────┬───────────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────┐
    │ VÉRIFICATION CONFLITS                │
    │ - Si suppression de patients         │
    │ - Afficher qui est supprimé          │
    └──────────┬───────────────────────────┘
               │
               ▼
    ┌──────────────────────────────────────┐
    │ ASSIGNATION                          │
    │ chosen_events[best_key] = chosen_val │
    └──────────┬───────────────────────────┘
               │
               ▼
            (BOUCLE)
               │
               ▼ OUI
    ┌──────────────────────────────────────┐
    │ FIN                                  │
    │ Afficher récapitulatif complet       │
    │ Return chosen_events                 │
    └──────────────────────────────────────┘
```

