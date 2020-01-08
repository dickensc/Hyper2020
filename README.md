# HyPER2019
 Reworking of the Hyper Recommender system.
 
 The original HyPER recommender system made design decisions that were necessary for scalability with the PSL version being used in 2015. 
 However, thanks to recent advancements in the PSL grounding and inference process, the PSL system can now handle significantly larger and more complex queries.
 See *Srinivasan S., Augustine E., and Getoor L. 2020*.
 
 The primary goal of this reworking is to bring the HyPER recommendation system up to date with current PSL standards as a new starting point for further recommender system research.
 
 ```
 @conference {,
     title = {Tandem Inference: An Out-of-Core Streaming Algorithm For Very Large-Scale Relational Inference},
     booktitle = {34th AAAI Conference on Artificial Intelligence},
     year = {2020},
     month = {11/2019},
     author = {Sriram Srinivasan* and Eriq Augustine* and Lise Getoor}
 }
 ```
 
 ## Squared hinge-loss potentials
 The original 2015 HyPER system used primarily linear hinge-loss functions. 
 Non-squared potentials tend to encourage a "winner take all" optimization, pushing inferred predicate values to extreme, 0 or 1, values.
 Squard hinge-loss potentials encourage more of a trade off.
 
 An updated version of HyPER was used to develop a Fairness-aware Hybrid Recommender System which utilized only squared hinge-loss potentials.
 See *Golnoosh Farnadi and Kouki, Pigi and Spencer K. Thompson and Sriram Srinivasan and Lise Getoor 2018*
 
 Lastly, a comparison between the two approaches was performed in January 2020 showing little difference infering with linear or quadratic potentials.
 See [link](https://docs.google.com/spreadsheets/d/1-n_3-3ZeKUQZpC87DnU-oHFe5Vw_20EBBo12uTWHNPk/edit#gid=0)
 
 This version adopts the squared hinge-loss potentials methodology.


```
@conference {337,
    title = {A Fairness-aware Hybrid Recommender System},
    booktitle = {The 2nd FATREC Workshop on Responsible Recommendation},
    year = {2018},
    author = {Golnoosh Farnadi and Kouki, Pigi and Spencer K. Thompson and Sriram Srinivasan and Lise Getoor}
}
```

## Blocking Predicates

## Rule Pruning
 
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
 
 
