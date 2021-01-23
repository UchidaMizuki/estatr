
<!-- README.md is generated from README.Rmd. Please edit that file -->

# estatr

<!-- badges: start -->
<!-- badges: end -->

e-Stat
APIのクエリの作成（データ絞り込み）・データのダウンロードを行うためのRパッケージです．
コードの対応関係の確認等に時間を割かずに，単純なデータフレーム操作でダウンロードデータの絞り込み・整形が可能です．

**このサービスは、政府統計総合窓口(e-Stat)のAPI機能を使用していますが、サービスの内容は国によって保証されたものではありません。**

## インストール

CRAN上には公開されていないため，GitHubからインストールしてください．

    # install.packages("devtools")
    devtools::install_github("UchidaMizuki/estatr")

## データ取得の流れ

### estatオブジェクトの作成

    library(estatr)
    library(magrittr)
    library(dplyr)

    appId <- "Your own e-Stat appId"

    # estatオブジェクト作成例
    my_estat <- estat$new(statsDataId = "0003413193", 
                          appId = appId)
    #> このサービスは、政府統計総合窓口(e-Stat)のAPI機能を使用していますが、サービスの内容は国によって保証されたものではありません。

### データ概要の確認

必要に応じて`info`でデータの概要を確認できます．

    my_estat$info
    #> # A tibble: 17 x 2
    #>    name              value                                                      
    #>    <chr>             <chr>                                                      
    #>  1 STAT_NAME         "00200523_住民基本台帳人口移動報告"                        
    #>  2 GOV_ORG           "00200_総務省"                                             
    #>  3 STATISTICS_NAME   "住民基本台帳人口移動報告 参考表　2018年～　（転入・転出市区町村別結果（移動者（外国人含む），日本人移動者，外~
    #>  4 TITLE             "003_移動前の住所地別転入者数（移動者（外国人含む），日本人移動者，外国人移動者）　－都道府県，市区町村（平成3~
    #>  5 CYCLE             "年次"                                                     
    #>  6 SURVEY_DATE       "201901-201912"                                            
    #>  7 OPEN_DATE         "2020-04-28"                                               
    #>  8 SMALL_AREA        "0"                                                        
    #>  9 COLLECT_AREA      "該当なし"                                                 
    #> 10 MAIN_CATEGORY     "02_人口・世帯"                                            
    #> 11 SUB_CATEGORY      "04_人口移動"                                              
    #> 12 OVERALL_TOTAL_NU~ "220566"                                                   
    #> 13 UPDATED_DATE      "2020-12-24"                                               
    #> 14 STATISTICS_NAME_~ "住民基本台帳人口移動報告_参考表　2018年～　（転入・転出市区町村別結果（移動者（外国人含む），日本人移動者，外~
    #> 15 DESCRIPTION       ""                                                         
    #> 16 TITLE_SPEC        "移動前の住所地別転入者数（移動者（外国人含む），日本人移動者，外国人移動者）　－都道府県，市区町村（平成31年・令~
    #> 17 releaseCount      "1"

### 属性情報の確認

`key`や`value`で属性情報を確認できます．
表章項目が存在する場合に限り，`value`に表章項目が格納されます．

    names(my_estat$key)
    #> [1] "移動後の住所地(現住地)2019～" "国籍"                        
    #> [3] "移動前の住所地(前住地)2019～" "年次"
    my_estat$value
    #> # A tibble: 1 x 4
    #>   code  name                     level unit 
    #>   <chr> <chr>                    <chr> <chr>
    #> 1 11    他市区町村からの転入者数 ""    人

`key`や`value`には各属性情報がデータフレームで格納されます．
例として`key`の「移動後の住所地(現住地)2019～」の属性情報を示します．

    my_estat$key$"移動後の住所地(現住地)2019～"
    #> # A tibble: 1,964 x 4
    #>    code  name         level parentCode
    #>    <chr> <chr>        <chr> <chr>     
    #>  1 01000 北海道       2     00005     
    #>  2 01100 札幌市       3     01000     
    #>  3 01101 札幌市中央区 4     01100     
    #>  4 01102 札幌市北区   4     01100     
    #>  5 01103 札幌市東区   4     01100     
    #>  6 01104 札幌市白石区 4     01100     
    #>  7 01105 札幌市豊平区 4     01100     
    #>  8 01106 札幌市南区   4     01100     
    #>  9 01107 札幌市西区   4     01100     
    #> 10 01108 札幌市厚別区 4     01100     
    #> # ... with 1,954 more rows

### 属性情報の絞り込み

`key`や`value`のデータフレームを上書きすることにより自動的に（`cdCat01`などの）クエリが作成できます．
データの上書きに`magrittr`パッケージの`%<>%`を使用することで，プログラムをシンプルにしています．

    # データ絞り込み例
    my_estat$key$"移動後の住所地(現住地)2019～" %<>%
      filter(name == "北海道")
    my_estat$key$"国籍" %<>%
      filter(name == "移動者")
    my_estat$key$"移動前の住所地(前住地)2019～" %<>%
      filter(level == "2")

    # `key`の絞り込みをやり直したい場合には，`restore_key()`メソッドを実行（全てのkeyが初期化される）．
    # my_estat$restore_key()

    # 同様に，`restore_value()`で`value`の絞り込みが初期化されます．

### データ取得

`get_data()`メソッドを実行するとデータが取得され，`data`にデータが格納されます．
`data`のkeyは，`code`・`name`・`level`等のそれぞれのラベルに対して設定されます．
`data`のvalueは，表章項目が存在する場合には，`項目_単位`という形式で出力されます．
ただし，単位が存在しない場合には単位が記載されず，表章項目が存在しない場合には単に`value`と名付けられます．

    my_estat$get_data()
    #> The total number of data is 38.
    #> Downloading data from lines 1 to 100000

    my_estat$data %>% 
      colnames()
    #>  [1] "code_移動後の住所地(現住地)2019～"      
    #>  [2] "code_国籍"                              
    #>  [3] "code_移動前の住所地(前住地)2019～"      
    #>  [4] "code_年次"                              
    #>  [5] "name_移動後の住所地(現住地)2019～"      
    #>  [6] "name_国籍"                              
    #>  [7] "name_移動前の住所地(前住地)2019～"      
    #>  [8] "name_年次"                              
    #>  [9] "level_移動後の住所地(現住地)2019～"     
    #> [10] "level_国籍"                             
    #> [11] "level_移動前の住所地(前住地)2019～"     
    #> [12] "level_年次"                             
    #> [13] "parentCode_移動後の住所地(現住地)2019～"
    #> [14] "parentCode_移動前の住所地(前住地)2019～"
    #> [15] "他市区町村からの転入者数_人"

    my_estat$data %>% 
      select("name_移動後の住所地(現住地)2019～", "name_移動前の住所地(前住地)2019～", "他市区町村からの転入者数_人")
    #> # A tibble: 38 x 3
    #>    `name_移動後の住所地(現住地)2019～`~ `name_移動前の住所地(前住地)2019～`~ 他市区町村からの転入者数_人~
    #>    <chr>                       <chr>                                       <dbl>
    #>  1 北海道                      北海道                                     190867
    #>  2 北海道                      青森県                                       2191
    #>  3 北海道                      岩手県                                        936
    #>  4 北海道                      宮城県                                       2257
    #>  5 北海道                      秋田県                                        606
    #>  6 北海道                      福島県                                        809
    #>  7 北海道                      茨城県                                       1526
    #>  8 北海道                      栃木県                                        936
    #>  9 北海道                      群馬県                                        610
    #> 10 北海道                      埼玉県                                       3838
    #> # ... with 28 more rows
