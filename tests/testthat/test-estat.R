get_appId <- function() {
  if (nrow(keyring::key_list(service = "e-Stat-appId")) == 0) {
    skip('Set the appId  by keyring::key_set("e-Stat-appId")')
  }

  keyring::key_get("e-Stat-appId")
}

test_that("00200523_jumin-kihon-daicho-jinko-ido-chosa", {
  appId <- get_appId()
  .estat <- estat$new("0003413193", appId)

  .estat$key[[stringi::stri_unescape_unicode("\\u79fb\\u52d5\\u5f8c\\u306e\\u4f4f\\u6240\\u5730(\\u73fe\\u4f4f\\u5730)2019\\uff5e")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u5317\\u6d77\\u9053"))
  .estat$key[[stringi::stri_unescape_unicode("\\u56fd\\u7c4d")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u79fb\\u52d5\\u8005"))
  .estat$key[[stringi::stri_unescape_unicode("\\u79fb\\u52d5\\u524d\\u306e\\u4f4f\\u6240\\u5730(\\u524d\\u4f4f\\u5730)2019\\uff5e")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u7dcf\\u6570\\uff08\\u524d\\u4f4f\\u5730\\uff09"))

  .estat_data <- .estat$get_data()
  expect_s3_class(.estat_data, "data.frame")
})

test_that("00200521_kokuse-chosa", {
  appId <- get_appId()
  .estat <- estat$new("0000033787", appId)

  .estat$key[[stringi::stri_unescape_unicode("\\u5e74\\u9f62\\u968e\\u7d1a031470")]] %<>%
    filter(str_detect(name, stringi::stri_unescape_unicode("^\\\\d{1,2}\\uff5e\\\\d{1,2}\\u6b73$")) | name == stringi::stri_unescape_unicode("100\\u6b73\\u4ee5\\u4e0a"))
  .estat$key[[stringi::stri_unescape_unicode("\\u7537\\u5973031421")]] %<>%
    filter(name %in% c(stringi::stri_unescape_unicode("\\u7537"), stringi::stri_unescape_unicode("\\u5973")))
  .estat$key[[stringi::stri_unescape_unicode("\\u5730\\u57df030282")]] %<>%
    filter(code == "01000")

  .estat_data <- .estat$get_data()
  expect_s3_class(.estat_data, "data.frame")
})

test_that("00200552_keizai-census-kiso-chosa", {
  appId <- get_appId()
  .estat <- estat$new("0003032610", appId)

  .estat$key[[stringi::stri_unescape_unicode("H21_1-1\\u7d4c\\u55b6\\u7d44\\u7e544\\u533a\\u5206\\uff9b")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u6c11\\u55b6"))
  .estat$key[[stringi::stri_unescape_unicode("H21_8\\u958b\\u8a2d\\u6642\\u671f14\\u533a\\u5206")]] %<>%
    filter(name == stringi::stri_unescape_unicode("\\u7dcf\\u6570"))
  .estat$value %<>%
    filter(name == stringi::stri_unescape_unicode("\\u4e8b\\u696d\\u6240\\u6570"))

  .estat_data <- .estat$get_data()
  expect_s3_class(.estat_data, "data.frame")
})
