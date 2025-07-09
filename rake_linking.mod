# Sets
set SERVICES;  # Set of services
set RAKELINKS; # Set of rake links
set STATIONS;  # Set of stations

# Parameters
param T_a{SERVICES};  # Arrival time after service k (in minutes)
param T_d{SERVICES};  # Departure time for service k (in minutes)
param T_h;            # Minimum halt time at transit nodes (in minutes)
param T_clean;        # Minimum cleaning/preparation time (in minutes)
param D{SERVICES};    # Distance covered by service k (in kilometers)
param T_prime;  # Maximum allowed weekly rake time (10080 min)
param T_RJ {SERVICES};  # Travel time of service (in minutes)
param sta_arr {SERVICES} symbolic in STATIONS;
param sta_dep {SERVICES} symbolic in STATIONS;
param B;              # Maximum allowable distance for a rake before maintenance (in kilometers
param M1;             # Large constant for time constraints
param M2;             # Large constant for coaches constraints
param sta_origin{RAKELINKS}; # Origin station 
param sta_destination{RAKELINKS}; # destination station 
param T_origin{RAKELINKS};   # Origin time (in minutes)
param e1 ;  # Factor to adjust halt time for civil/operational constraints
param C {SERVICES};  # Number of coaches for each service



# Decision Variables
var X{SERVICES, RAKELINKS} binary; # X[k,j] = 1 if service k is assigned to rake link j
var Y{RAKELINKS} binary;           # Y[j] = 1 if a new rake is required for rake link j

# Objective: Minimize the number of rakes
minimize Total_Rakes:
    sum{j in RAKELINKS} Y[j];

# Constraints
# Service Assignment Constraint
subject to Service_Assignment {k in SERVICES}:
    sum{j in RAKELINKS} X[k,j] = 1;
    
# Rake Link Activation Constraint
  subject to Rake_Link_Activation {k in SERVICES, j in RAKELINKS}:
    X[k,j] <= Y[j];

# Distance Constraint
  subject to DistanceConstraint {j in RAKELINKS}:
    sum{k in SERVICES} D[k] * X[k,j] <= B;

# Total Operational Time Constraint
subject to TotalOperationalConstraint {j in RAKELINKS}:
    sum {k in SERVICES} (T_RJ[k] + T_clean) * X[k,j] <= T_prime;

# Haul time constraint: (Service k and k+1 (for k=2)must fit within halt time if linked)
subject to HaulTimeConstraint {j in RAKELINKS }:
    (T_a[3] - T_d[2]) * (X[2,j] + X[3,j] - 1) <= e1 * T_h;

# Constraint: Time and cleaning constraint with station check
  
subject to Time_Cleaning_Constraint_LB {k in 1..3, j in RAKELINKS: sta_arr[k] = sta_dep[k+1]}:
    T_d[k+1] - T_a[k] >= T_clean * (X[k,j] + X[k+1,j] - 1);

subject to Time_Cleaning_Constraint_UB {k in 1..3, j in RAKELINKS: sta_arr[k] = sta_dep[k+1]}:
    T_d[k+1] - T_a[k] <= T_clean + M1 * (1 - (X[k,j] + X[k+1,j] - 1));

subject to Commercial_Loss_Constraint {j in RAKELINKS:
    C[1] < C[2]}:
    M2*(1-X[1,j]) + C[1] * X[1,j] >= 0.9 * C[2] * X[2,j];

