;; thinking machines

(load "list.scm")
(load "octree.scm")
(load "input.scm")
(load "scheme-bricks.scm")


(define (make-bot id pos brick-id) (list id pos 0 0 brick-id 'none))
(define (bot-id b) (list-ref b 0))
(define (bot-pos b) (list-ref b 1))
(define (bot-dir b) (list-ref b 2))
(define (bot-clock b) (list-ref b 3))
(define (bot-brick-id b) (list-ref b 4))
(define (bot-action b) (list-ref b 5))
(define (bot-modify-pos b v) (list-replace b 1 v))
(define (bot-modify-dir b v) (list-replace b 2 v))
(define (bot-modify-clock b v) (list-replace b 3 v))
(define (bot-modify-action b v) (list-replace b 5 v))

(define (bot-run-code bot octree input bricks)
  (let ((bot (bot-modify-clock bot (+ 1 (bot-clock bot)))))
    ;; check gravity first
    (let ((here (octree-ref octree (bot-pos bot)))
          (under (octree-ref octree (vadd (vector 0 -1 0) (bot-pos bot)))))
      (if (not (eq? here 'e)) ;; 'in' a filled block, go up
          (bot-modify-pos bot (vadd (vector 0 1 0) (bot-pos bot)))
          (if (eq? under 'e) ;; nothing underneath, go down
              (bot-modify-pos bot (vadd (vector 0 -1 0) (bot-pos bot)))
              (apply 
               (eval (brick->sexpr (bricks-search bricks (bot-brick-id bot))))
               (list bot input))
              #;((bot-code bot) bot input)))))) ;; run code

(define (bot-in-front bot)
  (let ((d (modulo (bot-dir bot) 4)))
    (vadd
     (bot-pos bot)
     (if (eq? d 0) (vector 0 0 -1) (vector 0 0 0))
     (if (eq? d 1) (vector -1 0 0) (vector 0 0 0))
     (if (eq? d 2) (vector 0 0 1) (vector 0 0 0))
     (if (eq? d 3) (vector 1 0 0) (vector 0 0 0)))))

(define (bot-behind bot)
  (let ((d (modulo (bot-dir bot) 4)))
    (vadd
     (bot-pos bot)
     (if (eq? d 0) (vector 0 0 1) (vector 0 0 0))
     (if (eq? d 1) (vector 1 0 0) (vector 0 0 0))
     (if (eq? d 2) (vector 0 0 -1) (vector 0 0 0))
     (if (eq? d 3) (vector -1 0 0) (vector 0 0 0)))))

(define (bot-do-movement bot input)
  (bot-modify-dir
   (bot-modify-pos 
    bot
    (if (input-key? input "w")
        (bot-in-front bot)
        (if (input-key? input "s")
            (bot-behind bot)
            (bot-pos bot))))
   (+ (bot-dir bot)
      (if (input-key? input "a") 1 0)
      (if (input-key? input "d") -1 0))))

(define controlled-bot 
  '(lambda (bot input)
     (bot-do-movement
      (if (input-key? input "z") 
          (bot-modify-action bot 'dig)
          (if (input-key? input "x") 
              (bot-modify-action bot 'remove)
              bot))
      input)))

(define default-bot '(lambda (bot input) bot))

(define (bot-run-action bot octree)
  (cond 
   ((eq? (bot-action bot) 'dig)
    (octree-delete octree (vadd (vector 0 -1 0) (bot-pos bot))))
   ((eq? (bot-action bot) 'remove)
    (octree-delete octree (bot-in-front bot)))
   (else octree)))
  
(define (make-bots l) (list l))
(define (bots-list bs) (list-ref bs 0)) 
(define (bots-modify-list bs v) (list-replace bs 0 v)) 

(define (bots-add-bot bs bot)
  (bots-modify-list 
   bs 
   (cons bot (bots-list bs))))

(define (bots-run-code bs octree input bricks)
  (bots-modify-list
   bs
   (map
    (lambda (bot)
      (bot-run-code bot octree input bricks))
    (bots-list bs))))

(define (bots-run-actions bs octree)
  (foldl
    (lambda (bot octree)
      (bot-run-action bot octree))
    octree
    (bots-list bs)))

(define (bots-octree-change? bs)
  (foldl
   (lambda (bot r)
     (if (and (not r) (or 
                       (eq? (bot-action bot) 'dig)
                       (eq? (bot-action bot) 'remove)))
         #t r))
   #f
   (bots-list bs)))

(define (bots-clear-actions bs)
  (bots-modify-list
   bs
   (map
    (lambda (bot)
      (bot-modify-action bot 'none))
    (bots-list bs))))