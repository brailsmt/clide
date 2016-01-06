(ns clide-server.core
  (:require [compojure.core :refer :all]
            [compojure.handler :as handler]
            [compojure.route :as route]))

(defn display-help
  "Display help"
  [arg]
  (name arg))

(defroutes clide
  "Define routes for serving up clide goodness"
  (GET "/clide" [] (display-help :clide-server))
  (GET "/clide/projects" [] (display-help :projects))
  (GET "/clide/config" [] (display-help :config))
  (GET "/clide/help" [] (display-help :help)))

(def app 
  (-> (handler/site clide)))
