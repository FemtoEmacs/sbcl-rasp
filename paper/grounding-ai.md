# Grounding generative AI in the real world

## List of authors

* Pedro Fernandes - primeiro autor
* * Philippos Costa / Nicole Hardy  - os dois serão convidados nessa ordem.
* * Eduardo Pereina
* * Nome a ser indicado pela NAIA
* * Thiago Daibes Padilha - autor sênior e encarregado da submissão

## Introduction

The physical grounding hypothesis, the Physical Symbol System Hypothesis and Neurosymbolic AI aren't new ideas. Adherents of the Physical Symbol System Hypothesis include Herbert Simon and Allen Newell. In 1976, when they won the Turing Award, they said in their acceptance lecture:

> The Physical Symbol System Hypothesis (PSSH). A physical symbol system has the
> > necessary and sufficient means for general intelligent action.


  Readers of the present paper may be asking the kind of circular question Warren McCulloch [2] made famous: What is a symbol that intelligence may use, and intelligence that it may use a symbol? The authors leave it to them to analyze Newell and Simon's Turing Lecture and determine what they mean by physical symbols. They argue that there is no “intelligence principle.”  But the lack of a simple *deus ex machina* does not imply that there are no structural requirements for intelligence. One such requirement is the ability to store and manipulate symbols.

  Computer scientists and neuroscientists who adopted the PSSH soon run into a difficulty. However clever the scientists designing and implementing a physical symbol system, they would die before adding all the details present in the real world, society and language to their model. And they were clever. Herbert Simon won the Nobel Memorial Prize, and Joshua Lederberg won the Nobel Prize in Medicine. Marvin Minsky won the Turing Award. In other words, some designs are so complex that people can't implement them in a lifetime. Language has so many rules, and they change so fast, that AI researchers struggle to build a grammar checker or translator [3]. Common sense has so many rules that CyC researchers couldn't implement it in 30 years [4][5].

  John McCarthy discovered the enormous complexity of PSSH very early in the history of AI research: "The qualification problem ... arises when we try to express the conditions for actions. We can think of the robot as having a general rule that it can fly to Moscow if it has a ticket. But suppose the ticket turns out to be counterfeit, the airport is closed by a strike, or the robot has been disassembled. To express all these qualifications in the antecedent of a conditional would make the rule unmanageably large, and we could never be sure we had thought of everything."


  In the heroic times of Artificial Intelligence, researchers worked with both symbolic systems and neural networks. Marvin Minsky, whom many consider the paragon of PSSH, wrote a thesis on neural networks [7].   In 1951, he co-built SNARC (Stochastic Neural Analog Reinforcement Calculator), which is widely considered the world's first artificial self-learning neural network machine. [8,9].

  With the rise of Generative AI after 2017, and the publication of a paper on the Transformer architecture [10], people began to notice that neural networks had problems complementary to PSSH.

  Neurosymbolic AI, which found a strong champion in Gary Marcus [11], proposes a hybrid system: generative models provide imense detail, while PSSH provides trustworthiness.

  The Physical Grounding Hypothesis was proposed in 1990 by Rodney Brooks: "Nouvelle AI is based on the physical grounding hypothesis. This hypothesis states that to build an intelligent system, it is necessary to ground its representations in the physical world." We left out the second part of Rodney Brooks, because we don't believe in it: "Our experience with this approach is that once this commitment is made, the need for traditional symbolic representations soon fades entirely." 

## Physical grounding

  We will start this section by making it clear that there isn't such a thing as an information processing system that is absolutely trustworthy. We can reduce hallucination in a neurosymbolic AI, but a residual margin for spluttering, juddering and failure will always remain.

  We were inspired by the PERCEPT platform for grounding a Generative AI in the physical world [13,14, 15]. 

To train a generative AI for single-cell RNA-seq, members of Jeffrey Ishizuka’s laboratory use the Cell2Sentence algorithm to convert sequencing data into text. Growing cancer cells in vitro allows researchers to test drugs. However, Perry and colleagues explain that many immunotherapies with promising preclinical results fail in clinical trials, partly because experimental models do not adequately represent human tumor–immune interactions. In PERCEPT, they therefore prepare cultures containing tumor and immune cells from patient samples. They expose portions of these cultures to treatments and leave others unstimulated as controls.

Single-cell RNA sequencing measures gene expression separately in thousands of cells from the treated and control cultures. The expression “single-cell” means that each cell’s RNA is measured separately, allowing researchers to distinguish individual cells and different cell types within the culture.
Suppose a treated cell expresses more of a gene than a control cell. That difference might come from the drug, or the two cells might already differ in cell type or state. To determine what changed, researchers would ideally measure the same cell before and after treatment. Sequencing, however, destroys the cell being measured.
Jeffrey Ishizuka’s collaborators use CINEMA-OT to identify patterns of gene expression associated with treatment. They use the remaining patterns to match treated and untreated cells that are otherwise similar.

Each match estimates how a treated cell might have behaved without the drug. These counterfactual matches allow researchers to compare gene-expression profiles and estimate treatment effects. This resembles comparing treatment and control groups in a clinical trial, although the cell matches are computed rather than established by random assignment [13,15].

The authors developed a system to minimize hallucinations from medical Generative AI for a limited kind of queries. Physicians often want answers restricted to a well-defined set of papers. These papers, which can be downloaded as PDF, DOCX, and other formats, are converted to Markdown text. Biomedical survival and response plots are represented as sexpr, the traditional PSSH data structure. Diagnostic images (MRI, CT scans, etc.) are also represented as sexpr. Generative AI handles these textual representations of data much better than the original images and plots. If a human is reading the paper, a command in a special editor renders images or plots back into a form similar to the original publication.

When the query is submitted to the medical AI, the documentation is pasted together. We could say the medical AI is doing an open-book test. In their benchmarks, the authors always submitted the questionnaire together with the questions. However, we can envision physicians who subscribe to an AI service having a library of textfyed articles, guidelines and laboratory data, such as single-cell RNA-seqs.  

  References

  [1] Newell, Allen, and Herbert A. Simon. “Computer Science as Empirical Inquiry: Symbols and Search.” Communications of the ACM 19, no. 3 (March 1976): 113–126. https://doi.org/10.1145/360018.360022. Accessed October 19, 2026.

  [2] McCulloch, W.S. [1961]. What is a number, that a man may know it, and a man, that he may know a number. General Semantics Bulletin Nos. 26 and 27 (1961), 7–18.

  [3] Briscoe, Ted, and John Carroll. “Robust Accurate Statistical Annotation of General Text.” In Proceedings of the 3rd International Conference on Language Resources and Evaluation (LREC 2002), 1499–1504, 2002.

  [4] Lenat, Douglas B. “CYC: A Large-Scale Investment in Knowledge Infrastructure.” Communications of the ACM 38, no. 11 (1995): 33–38.

  [5] Lenat, Douglas, Mayank Prakash, and Mary Shepherd. “CYC: Using Common Sense Knowledge to Overcome Brittleness and Knowledge Acquisition Bottlenecks.” AI Magazine 6, no. 4 (1985): 65–85.

  [6] McCarthy, J. (1977). Epistemological problems of artificial intelligence. In *Proceedings of the 5th International Joint Conference on Artificial Intelligence - Volume 2* (IJCAI'77), 1038–1044. 


  [7] Minsky, Marvin Lee. Theory of Neural-Analog Reinforcement Systems and Its Application to the Brain-Model Problem. Ph.D. dissertation, Princeton University, 1954. Princeton University Library. Accessed October 19, 2026. 

  [8] Minsky, M. (1952). *A Neural-Analogue Calculator Based upon a Probability Model of Reinforcement* (Technical Report). Harvard University Psychological Laboratories.


  [9] Minsky, M. L. (1954). *Theory of Neural-Analog Reinforcement Systems and Its Application to the Brain-Model Problem* (Doctoral dissertation). Princeton University.


  [10] Vaswani, A., Shazeer, N., Parmar, N., Uszkoreit, J., Jones, L., Gomez, A. N., Kaiser, Ł., & Polosukhin, I. (2017). Attention is all you need. *Advances in Neural Information Processing Systems*, 30, 5998–6008.


  [11] Lenat, D. B., & Marcus, G. (2023). *Getting from Generative AI to Trustworthy AI: What LLMs might learn from Cyc* (arXiv:2308.04445). arXiv. https://doi.org


  [12] Brooks, Rodney A. “Elephants Don’t Play Chess.” Robotics and Autonomous Systems 6, nos. 1–2 (1990): 3–15.

  [13] Perry, C., et al. “Perturbational Single-Cell Profiling of Patient Tumors Defines Lineage- and Context-Specific Programs of Innate Immune Resistance.” bioRxiv, preprint, version 1, December 12, 2025. https://doi.org/10.64898/2025.12.09.693245. Accessed October 19, 2026.

  [14] Rizvi, Syed Asad, et al. “Scaling Large Language Models for Next-Generation Single-Cell Analysis.” bioRxiv, preprint, version 4, January 1, 2026. https://doi.org/10.1101/2025.04.14.648850. Accessed October 19, 2026.

  [15] Dong, Mingze, et al. “Causal Identification of Single-Cell Experimental Perturbation Effects with CINEMA-OT.” Nature Methods 20 (2023): 1769–1779. https://doi.org/10.1038/s41592-023-02040-5. Accessed October 19, 2026.