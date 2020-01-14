# HyPER2020

 Reworking of the Hyper Recommender system.
 
 The primary goal of this reworking is to bring the HyPER recommendation system up to date with current PSL standards as a new starting point for further recommender system research.
 
 ## Running Experiments with run.sh
 ./run.sh will perform all the experiments that are intended to find the best possible default settings for the Hyper Reccomender system.
 
 Experiments are ran using both the lastfm and yelp datasets.
 ./run.sh wil perform weightlearning and evaluations for all 5 splits of data found in https://linqs-data.soe.ucsc.edu/public/hyper2020/<lastfm.zip, yelp.zip>.
 For each split it will run GaussianProcessPrior weight learning (piecewise sudo likelihood), and evaluation for both uniform and learned weights.
 Furthermore, for each split linear, quadratic, and original/mixture hingle loss potentials for rules are used.
 
 The output is stored in a results directory with a unique path for each experiment.
 
 Currently results for an entire run in January 2020 have been stored [here](https://docs.google.com/spreadsheets/d/1-n_3-3ZeKUQZpC87DnU-oHFe5Vw_20EBBo12uTWHNPk/edit#gid=0)
 
 ## Hinge-loss potentials
 The original 2015 HyPER system used primarily linear hinge-loss functions. 
 Non-squared potentials tend to encourage a "winner take all" optimization, pushing inferred predicate values to extreme, 0 or 1, values.
 Squard hinge-loss potentials encourage more of a trade off.
 
 An updated version of HyPER was used to develop a Fairness-aware Hybrid Recommender System which utilized only squared hinge-loss potentials.
 See *Golnoosh Farnadi and Kouki, Pigi and Spencer K. Thompson and Sriram Srinivasan and Lise Getoor 2018*
 
 Lastly, a comparison between three approaches was performed in January 2020 showing the differences between infering with linear or quadratic potentials.
 See [link](https://docs.google.com/spreadsheets/d/1-n_3-3ZeKUQZpC87DnU-oHFe5Vw_20EBBo12uTWHNPk/edit#gid=0)


```
@conference {337,
    title = {A Fairness-aware Hybrid Recommender System},
    booktitle = {The 2nd FATREC Workshop on Responsible Recommendation},
    year = {2018},
    author = {Golnoosh Farnadi and Kouki, Pigi and Spencer K. Thompson and Sriram Srinivasan and Lise Getoor}
}
```

## Blocking Predicates

 The original HyPER recommender system made design decisions that were necessary for scalability with the PSL version being used in 2015. 
 However, thanks to recent advancements in the PSL grounding and inference process, the PSL system can now handle significantly larger and more complex queries.
 See *Srinivasan S., Augustine E., and Getoor L. 2020*.
 
 If, hypothetically, all 'rated' blocking predicates were removed, then the number of groundings from the rules:
 
 1.0 : rating(U,I1) & sim_\<method\>_items(I1,I2) >> rating(U,I2)
 
 1.0 : rating(U1,I) & sim_\<method\>_users(U1,U2) >> rating(U2,I)
 
 could be approximated as is shown in the bullets below:
 
    - lastfm: 
        - Number of users ~= 1900
        - Number of items ~= 13000
        - Number of similarities in item/user canopy ~= N_SIM 
        - => number of groundings ~= 1900 * 13000 * N_SIM = 24,700,000 * N_SIM
        - if N_SIM was 50 then number of groundings ~= 1,235,000,000 = 1.235 * 10^9
    
    - yelp: 
        - Number of users ~= 29000
        - Number of items ~= 4000
        - Number of similarities in item/user canopy ~= N_SIM 
        - => number of groundings ~= 29000 * 4000 * N_SIM = 116,000,000 * N_SIM
        - if N_SIM was 50 then number of groundings ~= 5,800,000,000 = 5.8 * 10^9
        
  There are, in the original Hyper system, 9 of these similarity based rules. Thus the number of groundings is on the order of tens of billions, which is reaching the capacity of PSL inference.
  
  If we perform rule pruning, we could potentially filter out the unnecessary rules and then perform inference without blocking.  
  
  We ability to tune amount of blocking.
      - Mixing pairwise similarity blocking with "community"


  ```
 @conference {,
     title = {Tandem Inference: An Out-of-Core Streaming Algorithm For Very Large-Scale Relational Inference},
     booktitle = {34th AAAI Conference on Artificial Intelligence},
     year = {2020},
     month = {11/2019},
     author = {Sriram Srinivasan* and Eriq Augustine* and Lise Getoor}
 }
 ```

## Rule Pruning

Currently there are potentitailly redundant relations in the rules shown below.

```
// Similarities like Pearson, Cosine, and Adjusted Cosine Similarity between items.
1.0 :  rated(U,I1) & rated(U,I2) & rating(U,I1) & sim_pearson_items(I1,I2) >> rating(U,I2)
1.0 :  rated(U,I1) & rated(U,I2) & rating(U,I1) & sim_cosine_items(I1,I2) >> rating(U,I2)
1.0 :  rated(U,I1) & rated(U,I2) & rating(U,I1) & sim_adjcos_items(I1,I2) >> rating(U,I2)

// Similarities like Pearson and Cosine Similarity between users.
1.0 :  rated(U1,I) & rated(U2,I) & rating(U1,I) & sim_pearson_users(U1,U2) >> rating(U2,I)
1.0 :  rated(U1,I) & rated(U2,I) & rating(U1,I) & sim_cosine_users(U1,U2) >> rating(U2,I)

// Other low dimension space similarities like Matrix Factorization Cosine and Euclidean Similarity between users.
1.0 :  user(U1) & user(U2) & item(I) & rating(U1,I) & rated(U1,I) &rated(U2,I) & sim_mf_cosine_users(U1,U2) >> rating(U2,I)
1.0 :  user(U1) & user(U2) & item(I) & rating(U1,I) & rated(U1,I) &rated(U2,I) & sim_mf_euclidean_users(U1,U2) >> rating(U2,I)

// Other low dimension space similarities like Matrix Factorization Cosine and Euclidean Similarity between items.
1.0 :  user(U) & item(I1) & item(I2) & rating(U,I1) & rated(U,I1) & rated(U,I2) & sim_mf_cosine_items(I1,I2) >> rating(U,I2)
1.0 :  user(U) & item(I1) & item(I2) & rating(U,I1) & rated(U,I1) & rated(U,I2) & sim_mf_euclidean_items(I1,I2) >> rating(U,I2)

// Predictions by different other methods like SGD, Item based Pearson methods, and BPMF methods.
1.0 : sgd_rating(U,I) >> rating(U,I)
1.0 : rating(U,I) >> sgd_rating(U,I)
1.0 : item_pearson_rating(U,I) >> rating(U,I)
1.0 : rating(U,I) >> item_pearson_rating(U,I)
1.0 : bpmf_rating(U,I) >> rating(U,I)
1.0 : rating(U,I) >> bpmf_rating(U,I)

// Average prior of user rating and item ratings.
1.0  : user(U) & item(I) & rated(U,I) & avg_user_rating(U) >> rating(U,I)
1.0  : user(U) & item(I) & rated(U,I) & rating(U,I) >> avg_user_rating(U)
1.0  : user(U) & item(I) & rated(U,I) & avg_item_rating(I) >> rating(U,I)
1.0  : user(U) & item(I) & rated(U,I) & rating(U,I) >> avg_item_rating(I)

// Social rule of friendship influencing ratings.
1.0 : rated(U1,I) & rated(U2,I) & users_are_friends(U1,U2) & rating(U1,I) >> rating(U2,I)

// Content rule by Jaccard similarity.
1.0  :  rated(U,I1) & rated(U,I2) & rating(U,I1) & sim_content_items_jaccard(I1,I2) >> rating(U,I2)

// Two-sided overall prior (In original rec sys '15 paper but not in psl-examples)
1.0 : constant(C) & user(U) & item(I) & rated(U,I) & rating_prior(C) >> rating(U,I)
1.0 : constant(C) & user(I) & item(I) & rated(U,I) & rating(U,I) >> rating_prior(C)
```

We could experiment with the model sensitivity to removing rules of a similar structure.


## Learn / Eval Splits

How is it done?
 
 ## Original HyPER System

 "HyPER: A Flexible and Extensible Probabilistic Framework for Hybrid Recommender Systems" Pigi Kouki, Shobeir Fakhrei, James Foulds, Magdalini Eirinaki, Lise Getoor. Recommender Systems Conference (RecSys) 2015

 ```
 @InProceedings{kouki:recsys15,
     author = "Kouki, Pigi and Fakhraei, Shobeir and Foulds, James and Eirinaki, Magdalini and Getoor, Lise",
     title = "HyPER: A Flexible and Extensible Probabilistic Framework for Hybrid Recommender Systems",
     booktitle = "9th ACM Conference on Recommender Systems (RecSys 2015)", year = "2015",
     publisher = "ACM"
 }
 ```
 
 
