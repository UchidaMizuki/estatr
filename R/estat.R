#' Create e-Stat object
#'
#' @param statsDataId e-Stat statsDataId
#' @param appId Your own e-Stat appId
#' @param query query
#' @param url url
#'
#' @import dplyr
#' @import purrr
#' @import tibble
#' @import tidyr
#'
#' @importFrom readr parse_number
#' @importFrom magrittr %<>% equals not
#' @importFrom stringr str_c str_remove str_remove_all str_to_sentence str_glue str_replace_all str_detect
#' @importFrom R6 R6Class
#' @importFrom httr GET content
#'
#' @export
estat <- R6Class("estat",
                 public = list(
                   statsDataId = NULL,
                   query = NULL,
                   url = NULL,
                   total = NULL,
                   info = NULL,
                   key = NULL,
                   value = NULL,
                   note = NULL,
                   data = NULL,
                   initialize = function(statsDataId,
                                         appId,
                                         query = list(),
                                         url = "http://api.e-stat.go.jp/rest/3.0/app/json/getStatsData") {
                     message("\u3053\u306e\u30b5\u30fc\u30d3\u30b9\u306f\u3001\u653f\u5e9c\u7d71\u8a08\u7dcf\u5408\u7a93\u53e3(e-Stat)\u306eAPI\u6a5f\u80fd\u3092\u4f7f\u7528\u3057\u3066\u3044\u307e\u3059\u304c\u3001\u30b5\u30fc\u30d3\u30b9\u306e\u5185\u5bb9\u306f\u56fd\u306b\u3088\u3063\u3066\u4fdd\u8a3c\u3055\u308c\u305f\u3082\u306e\u3067\u306f\u3042\u308a\u307e\u305b\u3093\u3002")

                     self$statsDataId <- statsDataId
                     self$query <- query %>%
                       c(list(statsDataId = statsDataId,
                              appId = appId,
                              lang = "J"))
                     self$url <- url

                     Sys.sleep(1)
                     GET_STATS_DATA <- GET(url = url,
                                           query = self$query %>%
                                             c(list(cntGetFlg = "Y",
                                                    metaGetFlg = "Y"))) %>%
                       content() %>%
                       pluck("GET_STATS_DATA")

                     if (GET_STATS_DATA$RESULT$STATUS != 0) {
                       stop(GET_STATS_DATA$RESULT$ERROR_MSG)
                     }

                     self$total <- GET_STATS_DATA %>%
                       pluck("STATISTICAL_DATA", "RESULT_INF", "TOTAL_NUMBER")
                     self$info <- GET_STATS_DATA %>%
                       pluck("STATISTICAL_DATA", "TABLE_INF") %>%
                       enframe() %>%
                       filter(name != "@id") %>%
                       mutate(value = value %>%
                                map_chr(. %>%
                                          str_c(collapse = "_")))

                     CLASS_OBJ <- GET_STATS_DATA %>%
                       pluck("STATISTICAL_DATA", "CLASS_INF", "CLASS_OBJ")

                     # set key
                     private$key_id <- CLASS_OBJ %>%
                       keep(. %>%
                              pluck("@id") %>%
                              equals("tab") %>%
                              not()) %>%
                       map_chr(. %>%
                                 pluck("@id"))
                     private$key_name <- CLASS_OBJ %>%
                       keep(. %>%
                              pluck("@id") %>%
                              equals("tab") %>%
                              not()) %>%
                       map_chr(. %>%
                                 pluck("@name"))
                     private$key_raw <- CLASS_OBJ %>%
                       keep(. %>%
                              pluck("@id") %>%
                              equals("tab") %>%
                              not()) %>%
                       map(. %>%
                             pluck("CLASS") %>%
                             bind_rows() %>%
                             rename_with(. %>%
                                           str_remove("^@")) %>%
                             mutate(across(name,
                                           . %>%
                                             str_remove_all("\\s")))) %>%
                       set_names(private$key_name)
                     self$key <- private$key_raw

                     # set value
                     private$value_raw <- CLASS_OBJ %>%
                       keep(. %>%
                              pluck("@id") %>%
                              equals("tab")) %>%
                       first() %>%
                       pluck("CLASS") %>%
                       bind_rows() %>%
                       rename_with(. %>%
                                     str_remove("^@")) %>%
                       mutate(across(any_of("name"),
                                     . %>%
                                       str_remove_all("\\s")))
                     self$value <- private$value_raw
                   },
                   get_data = function() {
                     limit_downloads <- 10 ^ 5
                     limit_items <- 10 ^ 2

                     # check key
                     private$key_id %>%
                       seq_along() %>%
                       walk(~ {
                         if (nrow(self$key[[.x]]) == 0) {
                           stop(str_glue('The key for "{names(self$key)[.x]}" is empty.'))
                         }
                       })

                     # make key query
                     code_key <- private$key_raw %>%
                       map(. %>%
                             pull(code))
                     query_key <- tibble(id = private$key_id %>%
                                           str_to_sentence() %>%
                                           str_c("cd", .)) %>%
                       rowid_to_column() %>%
                       mutate(code = rowid %>%
                                map_chr(~ {
                                  if (setequal(self$key[[.x]]$code, code_key[[.x]])) {
                                    NA_character_
                                  } else {
                                    if (length(self$key[[.x]]$code) > limit_items) {
                                      stop(str_glue('The number of items in "{names(self$key)[.x]}" is too many (up to {limit_items} items per attribute). This error can be avoided by avoiding the use of not-equals.'))
                                    }

                                    self$key[[.x]]$code %>%
                                      str_c(collapse = ",")
                                  }
                                }),
                              .keep = "unused") %>%
                       drop_na(code)

                     # make value query
                     if (nrow(private$value_raw) >= 1) {
                       if (setequal(self$value$code, private$value_raw$code)) {
                         query_value <- tibble()
                       } else {
                         if (length(self$value$code) > limit_items) {
                           stop(str_glue('The number of items in "tab" is too many (up to {limit_items} items per attribute). This error can be avoided by avoiding the use of not-equals.'))
                         }

                         query_value <- tibble(id = "cdTab",
                                               code = self$value$code %>%
                                                 str_c(collapse = ","))
                       }
                     } else {
                       query_value <- tibble()
                     }

                     query <- bind_rows(query_key,
                                        query_value)

                     if (nrow(query) > 0) {
                       query <- query %>%
                         pull(code) %>%
                         as.list() %>%
                         set_names(query$id) %>%
                         c(self$query)
                     } else {
                       query <- self$query
                     }

                     # get total
                     Sys.sleep(1)
                     GET_STATS_DATA <- GET(url = self$url,
                                           query = query %>%
                                             c(list(cntGetFlg = "Y"))) %>%
                       content() %>%
                       pluck("GET_STATS_DATA")

                     if (GET_STATS_DATA$RESULT$STATUS != 0) {
                       stop(GET_STATS_DATA$RESULT$ERROR_MSG)
                     }

                     total <- GET_STATS_DATA %>%
                       pluck("STATISTICAL_DATA", "RESULT_INF", "TOTAL_NUMBER")
                     print(str_glue("The total number of data is {total}."))

                     # key
                     key <- list(self$key, names(self$key)) %>%
                       pmap_df(~ .x %>%
                                 mutate(col_name = .y))

                     # get data
                     self$data <- seq(1, total, limit_downloads) %>%
                       map_df(function(startPosition) {

                         endPosition <- format(startPosition + limit_downloads - 1,
                                               scientific = F)
                         print(str_glue("Downloading data from lines {startPosition} to {endPosition}"))

                         Sys.sleep(1)
                         GET_STATS_DATA <- GET(url = self$url,
                                               query = query %>%
                                                 c(list(startPosition = format(startPosition,
                                                                               scientific = F),
                                                        limit_downloads = format(limit_downloads,
                                                                       scientific = F)))) %>%
                           content() %>%
                           pluck("GET_STATS_DATA")

                         if (GET_STATS_DATA$RESULT$STATUS != 0) {
                           stop(GET_STATS_DATA$RESULT$ERROR_MSG)
                         }

                         DATA_INF <- GET_STATS_DATA %>%
                           pluck("STATISTICAL_DATA", "DATA_INF")

                         if (startPosition == 1) {
                           self$note <- DATA_INF %>%
                             pluck("NOTE") %>%
                             enframe() %>%
                             mutate(value = value %>%
                                      map_chr(. %>%
                                                str_c(collapse = "_")))
                         }

                         VALUE <- DATA_INF %>%
                           pluck("VALUE") %>%
                           bind_rows() %>%
                           rename(value = `$`) %>%
                           rename_with(. %>%
                                         str_remove("^@") %>%
                                         str_replace_all(private$key_name %>%
                                                           set_names(private$key_id))) %>%
                           mutate(across(value,
                                         . %>%
                                           parse_number(na = c("***"))))

                         if (nrow(private$value_raw) >= 1) {
                           VALUE %<>%
                             left_join(self$value %>%
                                         select(code, name),
                                       by = c("tab" = "code")) %>%
                             select(-tab) %>%
                             mutate(unit = if(exists("unit", where = .)) unit else "") %>%
                             replace_na(list(unit = "")) %>%
                             pivot_wider(names_from = c(name, unit),
                                         names_glue = '{name}{dplyr::if_else(unit == "", "", "_")}{unit}',
                                         values_from = value) %>%
                             rowid_to_column()

                           VALUE %>%
                             select(rowid, all_of(private$key_name)) %>%
                             pivot_longer(-rowid,
                                          names_to = "col_name",
                                          values_to = "code") %>%
                             left_join(key,
                                       by = c("col_name", "code")) %>%
                             pivot_wider(names_from = col_name,
                                         values_from = -c(rowid, col_name)) %>%
                             select(-where(~ all(is.na(.)))) %>%
                             left_join(VALUE %>%
                                         select(-all_of(private$key_name)),
                                       by = "rowid") %>%
                             select(-rowid)
                         } else {
                           VALUE %<>%
                             rowid_to_column()

                           VALUE %>%
                             select(-value) %>%
                             pivot_longer(-rowid,
                                          names_to = "col_name",
                                          values_to = "code") %>%
                             left_join(key,
                                       by = c("col_name", "code")) %>%
                             pivot_wider(names_from = col_name,
                                         values_from = -c(rowid, col_name)) %>%
                             select(-where(~ all(is.na(.)))) %>%
                             left_join(VALUE %>%
                                         select(rowid, value),
                                       by = "rowid") %>%
                             select(-rowid)
                         }
                       })
                   },
                   restore_key = function() {
                     self$key <- private$key_raw
                   },
                   restore_value = function() {
                     self$value <- private$value_raw
                   }
                 ),
                 private = list(
                   key_id = NULL,
                   key_name = NULL,
                   key_raw = NULL,
                   value_raw = NULL
                 ))
