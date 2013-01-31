(load "octree.scm")

(define (make-block pos size value)
  (with-state
   (hint-wire)
   (wire-colour 0)

   (colour (cond 
            ((eq? value 0) (vector 1 0 0))
            ((eq? value 1) (vector 1 1 0))
            ((eq? value 2) (vector 1 0 1))))
   
   (translate pos)
   (scale size)
   (translate (vector 0.5 0.5 0.5))
   (build-cube)))

(define (block-view-builder o x y z depth)
  (let ((s (/ octree-size (expt 2 depth) 2)))
    (cond
     ((eq? o 'e) 'e)
     ((not (vector? o)) (make-block (vector x y z) (* s 2) o))
     (else
      (vector
       (block-view-builder (octree-branch o 0) x y z (+ depth 1))
       (block-view-builder (octree-branch o 1) (+ x s) y z (+ depth 1))
       (block-view-builder (octree-branch o 2) x (+ y s) z (+ depth 1))
       (block-view-builder (octree-branch o 3) (+ x s) (+ y s) z (+ depth 1))
       (block-view-builder (octree-branch o 4) x y (+ z s) (+ depth 1))
       (block-view-builder (octree-branch o 5) (+ x s) y (+ z s) (+ depth 1))
       (block-view-builder (octree-branch o 6) x (+ y s) (+ z s) (+ depth 1))
       (block-view-builder (octree-branch o 7) (+ x s) (+ y s) (+ z s) (+ depth 1)))))))


(define (make-block-view octree)
  (block-view-builder octree 0 0 0 0))

(define (block-view-destroy bv)
  (define (_ o)
    (cond
     ((eq? o 'e) 'e)
     ((not (vector? o)) (destroy o) 'e)
     (else
      (vector
       (_ (octree-branch o 0))
       (_ (octree-branch o 1))
       (_ (octree-branch o 2))
       (_ (octree-branch o 3))
       (_ (octree-branch o 4))
       (_ (octree-branch o 5))
       (_ (octree-branch o 6))
       (_ (octree-branch o 7))))))
  (_ bv))
  
(define (block-view-update bv octree)
  (define (_ o b x y z depth)
    (let ((s (/ octree-size (expt 2 depth) 2)))
      (cond
       ;; check for different types
       ((or 
         (and (vector? o)
              (not (vector? b))) ;; shattered
         (and (vector? b)
            (not (vector? o)))) ;; compressed
        ;; rebuild this subtree
        (block-view-destroy b)
        (block-view-builder o x y z depth))
       ;; deleted block
       ((and (not (vector? o))
             (eq? o 'e)
             (not (eq? b 'e)))
        (block-view-destroy b)
        'e)
       ;; new block
       ((and (not (vector? o))
             (not (eq? o 'e))
             (eq? b 'e))
        (block-view-builder o x y z depth))
       ((not (vector? o)) ;; todo: are assuming type doesn't change 
        b)       
       ;; they are the same, continue
       (else
        (vector
         (_ (octree-branch o 0)
            (octree-branch b 0) x y z (+ depth 1))
         (_ (octree-branch o 1)
            (octree-branch b 1) (+ x s) y z (+ depth 1))
         (_ (octree-branch o 2)
            (octree-branch b 2) x (+ y s) z (+ depth 1))
         (_ (octree-branch o 3)
            (octree-branch b 3) (+ x s) (+ y s) z (+ depth 1))
         (_ (octree-branch o 4)
            (octree-branch b 4) x y (+ z s) (+ depth 1))
         (_ (octree-branch o 5)
            (octree-branch b 5) (+ x s) y (+ z s) (+ depth 1))
         (_ (octree-branch o 6)
            (octree-branch b 6) x (+ y s) (+ z s) (+ depth 1))
         (_ (octree-branch o 7)
            (octree-branch b 7) (+ x s) (+ y s) (+ z s) (+ depth 1)))))))
  (_ octree bv 0 0 0 0))

