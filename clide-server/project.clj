(defproject clide-server "0.1.0-SNAPSHOT"
  :description "clide-server:  serve up clide web services"
  :url "http://www.github.com/brailsmt/clide"
  :license {:name "Eclipse Public License"
            :url "http://www.eclipse.org/legal/epl-v10.html"}
  :dependencies [[org.clojure/clojure "1.7.0"]
                 [ring/ring-core "1.4.0"]
                 [ring/ring-jetty-adapter "1.4.0"]
                 [org.clojure/tools.nrepl "0.2.12"]
                 [compojure "1.4.0"]]
  :plugins [[lein-ring "0.9.7"]]
  :ring {:handler clide-server.core/app
         :nrepl {:start? true}
         :reload-paths ["src"]})
