(**************************************************************)
(*   Copyright Dominique Larchey-Wendling [*]                 *)
(*                                                            *)
(*                             [*] Affiliation LORIA -- CNRS  *)
(**************************************************************)
(*      This file is distributed under the terms of the       *)
(*         CeCILL v2 FREE SOFTWARE LICENSE AGREEMENT          *)
(**************************************************************)

Require Import List Arith Nat Lia Relations.

From Undecidability.Shared.Libs.DLW.Utils 
  Require Import utils_tac utils_list finite.

From Undecidability.Shared.Libs.DLW.Vec 
  Require Import pos vec fin_quotient.

From Undecidability.TRAKHTENBROT
  Require Import notations fol_ops fo_terms fo_logic gfp.

Set Implicit Arguments.

Local Notation " e '#>' x " := (vec_pos e x).
Local Notation " e [ v / x ] " := (vec_change e x v).

Section discrete_quotient.

  (** We assume a finite signature, a finite and decidable model and a valuation 
      and we build the greatest bisimulation for this model, establishing that it
      is decidable and thus we can quotient the model under this bisim obtaining
      a discrete model which is "equivalent" *)

  Variables (Σ : fo_signature)
            (ls : list (syms Σ))
            (lr : list (rels Σ))
            (*HΣs : finite_t (syms Σ)*)
            (*HΣr : finite_t (rels Σ)*)
            (X : Type) (M : fo_model Σ X)  
            (fin : finite_t X) 
            (dec : fo_model_dec M)
            (φ : nat -> X).

  Implicit Type (R T : X -> X -> Prop).

  (** Construction of the greatest fixpoint of the following operator *)

  Let fom_op R x y :=
       (forall s, In s ls -> forall (v : vec _ (ar_syms Σ s)) p, R (fom_syms M s (v[x/p])) (fom_syms M s (v[y/p]))) 
    /\ (forall s, In s lr -> forall (v : vec _ (ar_rels Σ s)) p, fom_rels M s (v[x/p]) <-> fom_rels M s (v[y/p])).

  Let fom_op_mono R T : (forall x y, R x y -> T x y) -> (forall x y, fom_op R x y -> fom_op T x y).
  Proof. intros ? ? ? []; split; intros; auto. Qed. 

  Let fom_op_id x y : x = y -> fom_op (@eq _) x y.
  Proof. intros []; split; auto; tauto. Qed.

  Let fom_op_sym R x y : fom_op R y x -> fom_op (fun x y => R y x) x y.
  Proof. intros []; split; intros; auto; symmetry; auto. Qed.

  Let fom_op_trans R x z : (exists y, fom_op R x y /\ fom_op R y z)
                        -> fom_op (fun x z => exists y, R x y /\ R y z) x z.
  Proof.
    intros (y & H1 & H2); split; intros s Hs v p.
    + exists (fom_syms M s (v[y/p])); split; [ apply H1 | apply H2 ]; auto.
    + transitivity (fom_rels M s (v[y/p])); [ apply H1 | apply H2 ]; auto.
  Qed.

  Reserved Notation "x ≡ y" (at level 70, no associativity).

  Definition fom_eq := gfp fom_op.

  Infix "≡" := fom_eq.

  Let fom_eq_equiv : equiv _ fom_eq.
  Proof. apply gfp_equiv; auto. Qed.

  (** This involves the w-continuity of fom_op *)

  Let fom_eq_fix x y : fom_op fom_eq x y <-> x ≡ y.
  Proof. 
    apply gfp_fix; auto; clear x y.
    intros f Hf x y H; split; intros s Hs v p.
    + intros n.
      generalize (H n); intros (H1 & H2).
      apply H1; auto.
    + apply (H 0); auto.
  Qed.

  (** We build the greatest bisimulation which is an equivalence 
      and a fixpoint for the above operator *) 

  Fact fom_eq_refl x : x ≡ x.
  Proof. apply (proj1 fom_eq_equiv). Qed.

  Fact fom_eq_sym x y : x ≡ y -> y ≡ x.
  Proof. apply fom_eq_equiv. Qed.

  Fact fom_eq_trans x y z : x ≡ y -> y ≡ z -> x ≡ z.
  Proof. apply fom_eq_equiv. Qed.

  (* It is a congruence wrt to the model *)

  Fact fom_eq_syms x y s v p : In s ls -> x ≡ y -> fom_syms M s (v[x/p]) ≡ fom_syms M s (v[y/p]).
  Proof. intros; apply fom_eq_fix; auto. Qed. 
    
  Fact fom_eq_rels x y s v p : In s lr -> x ≡ y -> fom_rels M s (v[x/p]) <-> fom_rels M s (v[y/p]).
  Proof. intros; apply fom_eq_fix; auto. Qed.

  Hint Resolve fom_eq_refl fom_eq_sym fom_eq_trans fom_eq_syms fom_eq_rels.

  Theorem fom_eq_syms_full s v w : In s ls -> (forall p, v#>p ≡ w#>p) -> fom_syms M s v ≡ fom_syms M s w.
  Proof. intro; apply map_vec_pos_equiv; eauto. Qed.

  Theorem fom_eq_rels_full s v w : In s lr -> (forall p, v#>p ≡ w#>p) -> fom_rels M s v <-> fom_rels M s w.
  Proof. intro; apply map_vec_pos_equiv; eauto; tauto. Qed.

  Hint Resolve finite_t_vec finite_t_pos. 

  (** And because the signature is finite (ie the symbols and relations) 
                  the model M is finite and composed of decidable relations 

      We do have a decidable equivalence here *) 
 
  Fact fom_eq_dec : forall x y, { x ≡ y } + { ~ x ≡ y }.
  Proof.
    apply gfp_decidable; auto.
    intros R HR x y.
    apply (fol_bin_sem_dec fol_conj).
    + apply forall_list_sem_dec; intros.
      do 2 (apply (fol_quant_sem_dec fol_fa); auto; intros).
    + apply forall_list_sem_dec; intros.
      do 2 (apply (fol_quant_sem_dec fol_fa); auto; intros).
      apply (fol_bin_sem_dec fol_conj); 
        apply (fol_bin_sem_dec fol_imp); auto.
  Qed.

  Hint Resolve fom_eq_dec.

  (** And now we can build a discrete model with this equivalence 

      There is a (full) surjection from a discrete model based
      on pos n to M which preserves the semantics

    *)

  Section build_the_model.

    Let l := proj1_sig fin.
    Let Hl : forall x, In x l := proj2_sig fin.

    Let Q : fin_quotient fom_eq.
    Proof. apply decidable_EQUIV_fin_quotient with (l := l); eauto. Qed.

    Let n := fq_size Q.
    Let cls := fq_class Q.
    Let repr := fq_repr Q.
    Let E1 p : cls (repr p) = p.              Proof. apply fq_surj. Qed.
    Let E2 x y : x ≡ y <-> cls x = cls y.     Proof. apply fq_equiv. Qed.

    Let Md : fo_model Σ (pos n).
    Proof.
      exists.
      + intros s v; apply cls, (fom_syms M s), (vec_map repr v).
      + intros s v; apply (fom_rels M s), (vec_map repr v).
    Defined.

    Theorem fo_fin_model_discretize : 
      { n : nat & 
        { Md : fo_model Σ (pos n) &
          {_ : fo_model_dec Md & 
            { i : X -> pos n &
              { j : pos n -> X |
                  (forall x, i (j x) = x)
               /\ (forall s v, In s ls -> i (fom_syms M s v) = fom_syms Md s (vec_map i v))
               /\ (forall s v, In s lr -> fom_rels M s v <-> fom_rels Md s (vec_map i v))
                 } } } } }.
    Proof.
      exists n, Md; exists.
      { intros x y; simpl; apply dec. }
      exists cls, repr; msplit 2; auto.
      + intros s v Hs; simpl.
        apply E2.
        apply fom_eq_syms_full; auto.
        intros p; rewrite vec_map_map, vec_pos_map.
        apply E2; rewrite E1; auto.
      + intros s v Hs; simpl.
        apply fom_eq_rels_full; auto.
        intros p; rewrite vec_map_map, vec_pos_map.
        apply E2; rewrite E1; auto.
    Qed.

  End build_the_model.

End discrete_quotient.

Check fo_fin_model_discretize.
Print Assumptions fo_fin_model_discretize.

Section model_equiv.

  Variable (Σ : fo_signature) 
           (X : Type) (M : fo_model Σ X) 
           (Y : Type) (K : fo_model Σ Y) 
           (i : X -> Y) (j : Y -> X) (E : forall x, i (j x) = x)
           (ls : list (syms Σ))
           (lr : list (rels Σ))
           (Hs : forall s v, In s ls -> i (fom_syms M s v) = fom_syms K s (vec_map i v))
           (Hr : forall s v, In s lr -> fom_rels M s v <-> fom_rels K s (vec_map i v)).

  Theorem fo_model_term_eq t phi psi :
           (forall n, i (phi n) = psi n) 
        -> incl (fo_term_syms t) ls
        -> i (fo_term_sem (fom_syms M) phi t) 
         = fo_term_sem (X := nat) (fom_syms K) psi t.
  Proof.
    intros H.
    induction t as [ k | s w Hw ]; intros Hls; rew fot; auto.
    rewrite Hs.
    2: { apply Hls; rew fot; simpl; auto. }
    rewrite vec_map_map.
    f_equal.
    apply vec_map_ext.
    intros t Ht; apply Hw; auto.
    apply incl_tran with (2 := Hls).
    rew fot.
    intros u Hu; right.
    apply in_flat_map.
    exists t; split; auto.
    apply in_vec_list; auto.
  Qed.

  Theorem fo_model_project_equiv A phi psi :
           (forall n, i (phi n) = psi n) 
        -> incl (fol_syms A) ls
        -> incl (fol_rels A) lr
        -> fol_sem M phi A <-> fol_sem K psi A.
  Proof.
    revert phi psi.
    induction A as [ | r | b A HA B HB | q A HA ]; try (simpl; tauto); intros phi psi E' Hls Hlr.
    + simpl; rewrite Hr, vec_map_map.
      match goal with |- ?x <-> ?y => cut (x = y); [ intros ->; tauto | ] end.
      f_equal; apply vec_map_ext; intros t Ht.
      2: apply Hlr; simpl; auto.
      apply fo_model_term_eq; auto.
      apply in_vec_list in Ht.
      intros s H; apply Hls; simpl.
      apply in_flat_map.
      exists t; auto.
    + simpl; apply fol_bin_sem_ext.
      * apply HA; auto.
        - apply incl_tran with (2 := Hls); simpl.
          intros ? ?; apply in_or_app; auto.
        - apply incl_tran with (2 := Hlr); simpl.
          intros ? ?; apply in_or_app; auto.
      * apply HB; auto.
        - apply incl_tran with (2 := Hls); simpl.
          intros ? ?; apply in_or_app; auto.
        - apply incl_tran with (2 := Hlr); simpl.
          intros ? ?; apply in_or_app; auto.
    + destruct q; simpl; split.
      * intros (x & Hx).
        exists (i x).
        revert Hx; apply HA.
        - intros []; simpl; auto.
        - apply incl_tran with (2 := Hls), incl_refl.
        - apply incl_tran with (2 := Hlr), incl_refl.
      * intros (y & Hy).
        exists (j y).
        revert Hy; apply HA.
        - intros []; simpl; auto.
        - apply incl_tran with (2 := Hls), incl_refl.
        - apply incl_tran with (2 := Hlr), incl_refl.
      * intros H y. 
        generalize (H (j y)); apply HA.
        - intros []; simpl; auto.
        - apply incl_tran with (2 := Hls), incl_refl.
        - apply incl_tran with (2 := Hlr), incl_refl.
      * intros H x. 
        generalize (H (i x)); apply HA.
        - intros []; simpl; auto.
        - apply incl_tran with (2 := Hls), incl_refl.
        - apply incl_tran with (2 := Hlr), incl_refl.
  Qed.

End model_equiv.

Check fo_model_project_equiv.

Section discrete_removal.

  (** Provided the signature has finitely (listable) many functional symbols 
      and finitely many relational symbols, satisfiability of A in a finite
      and decidable model implies satisfiability of A in a finite, decidable
      and discrete model, in fact in a model based on the finite type (pos n) *)

  Theorem fo_discrete_removal Σ A :
             @fo_form_fin_dec_SAT Σ A
          -> (exists n, @fo_form_fin_discr_dec_SAT_in Σ A (pos n)).
  Proof.
    intros (X & M & Hfin & Hdec & phi & HA).
    set (ls := fol_syms A).
    set (lr := fol_rels A).
    destruct (fo_fin_model_discretize ls lr Hfin Hdec)
      as (n & Md & Mdec & i & j & E1 & E2 & E3).
    set (psy n := i (phi n)).
    exists n, (@pos_eq_dec _), Md, (finite_t_pos _) , Mdec, psy.
    revert HA.
    apply fo_model_project_equiv with (1 := E1) (ls := ls) (lr := lr); 
      unfold lr, ls; auto; apply incl_refl.
  Qed.

End discrete_removal.

Check fo_discrete_removal.
Print Assumptions fo_discrete_removal.

Theorem fo_form_fin_dec_SAT_fin_discr_dec Σ A :
            @fo_form_fin_dec_SAT Σ A 
         -> fo_form_fin_discr_dec_SAT A.
Proof.
  intros H.
  destruct fo_discrete_removal with (1 := H) (A := A)
    as (n & Hn); auto.
  exists (pos n); auto.
Qed.