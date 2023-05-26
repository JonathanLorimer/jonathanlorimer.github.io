{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE TypeApplications #-}

import Control.Lens
import Control.Monad
import Control.Monad.Trans.Class
import Control.Monad.Trans.Reader
import Data.Aeson
import Data.Aeson.KeyMap
import Data.Aeson.Lens
import Data.List (sortBy)
import Data.Maybe
import qualified Data.Text as T
import Data.Time
import Data.Time.Format.ISO8601
import Development.Shake
import Development.Shake.Classes
import Development.Shake.FilePath
import Development.Shake.Forward
import GHC.Generics (Generic)
import Slick
import System.Environment (lookupEnv)
import Text.Pandoc
    ( ReaderOptions(..),
      extensionsFromList,
      Extension(..),
      githubMarkdownExtensions )
import Text.Pandoc.Options (def)
import Slick.Pandoc
import Data.Foldable

{------------------------------------------------
                    Config
------------------------------------------------}

siteMeta :: SiteMeta
siteMeta =
    SiteMeta
        { siteAuthor = "jonathanlorimer"
        , baseUrl = "https://jonathanlorimer.dev"
        , siteTitle = "Jonathan Lorimer"
        , githubUser = "jonathanlorimer"
        , linkedInUser = "jonathan-lorimer-dev"
        , twitterUser = "jonathanlorime1"
        , mastodonUser = "jonathanlorimer"
        , image = "personalLogo1200px.png"
        }

type SiteM = ReaderT FilePath Action

forP' :: [a] -> (a -> SiteM b) -> SiteM [b]
forP' xs f = do
    env <- ask
    lift $ forP xs (\x -> runReaderT (f x) env)

withSiteMeta :: Value -> Value
withSiteMeta (Object obj) =
  case toJSON siteMeta of
    Object siteMetaObj -> Object $ obj `union` siteMetaObj
    _                  -> error "only add site meta to objects"
withSiteMeta _ = error "only add site meta to objects"

{------------------------------------------------
                  Data Models
------------------------------------------------}

data SiteMeta = SiteMeta
    { siteAuthor :: String
    , baseUrl :: String
    , siteTitle :: String
    , githubUser :: String
    , linkedInUser :: String
    , twitterUser :: String
    , mastodonUser :: String
    , image :: String
    }
    deriving (Generic, Eq, Ord, Show, ToJSON)

-- | Data for the index page
newtype PostsInfo = PostsInfo
    { posts :: [Post]
    }
    deriving (Generic, Show, FromJSON, ToJSON)

-- | Data for a blog post
data Post = Post
    { title :: String
    , author :: String
    , content :: String
    , url :: String
    , date :: String
    , description :: String
    , tags :: [Tag]
    , image :: Maybe String
    }
    deriving (Generic, Eq, Ord, Show, FromJSON, ToJSON, Binary)

type Tag = String

-- | Data for CV
data Bio = Bio
    { email :: String
    , location :: String
    , content :: String
    }
    deriving (Generic, Eq, Show, FromJSON, ToJSON, Binary)

newtype Technology = Technology {technology :: String}
    deriving (Generic, Eq, Show, FromJSON, ToJSON, Binary)

data Experience = Experience
    { company :: String
    , location :: String
    , title :: String
    , startDate :: String
    , endDate :: Maybe String
    , technologies :: [Technology]
    , content :: String
    }
    deriving (Generic, Eq, Show, FromJSON, Binary)

instance ToJSON Experience where
    toJSON = genericToJSON defaultOptions{omitNothingFields = True}

instance Ord Experience where
    Experience{startDate = sd1} `compare` Experience{startDate = sd2} =
        sd1 `compare` sd2

data Education = Education
    { schoolName :: String
    , startDate :: String
    , endDate :: String
    , credential :: String
    }
    deriving (Generic, Eq, Show, FromJSON, ToJSON, Binary)

data AboutMe = AboutMe
    { bio :: Bio
    , experience :: [Experience]
    , education :: [Education]
    }
    deriving (Generic, Eq, Show, FromJSON, ToJSON)

data AtomData = AtomData
    { title :: String
    , domain :: String
    , author :: String
    , posts :: [Post]
    , currentTime :: String
    , atomUrl :: String
    }
    deriving (Generic, ToJSON, Eq, Ord, Show)

{------------------------------------------------
                    Helpers
------------------------------------------------}
mdToHTML :: T.Text -> Action Value
mdToHTML = markdownToHTMLWithOpts markdownOptions defaultHtml5Options
  where
    markdownOptions :: ReaderOptions
    markdownOptions =  def {
      readerExtensions = fold
       [ extensionsFromList
         [ Ext_yaml_metadata_block
         , Ext_fenced_code_attributes
         , Ext_auto_identifiers
         , Ext_footnotes
         , Ext_footnotes
         , Ext_link_attributes
         , Ext_pipe_tables
         ]
       , githubMarkdownExtensions
       ]
    }

{------------------------------------------------
                    Builders
------------------------------------------------}
buildExperience :: FilePath -> Action Experience
buildExperience srcPath = cacheAction ("build" :: T.Text, srcPath) $ do
    liftIO . putStrLn $ "Rebuilding aboutme/experience: " <> srcPath
    experienceContent <- readFile' srcPath
    -- load post content and metadata as JSON blob
    experienceData <- mdToHTML . T.pack $ experienceContent
    convert experienceData

buildBio :: FilePath -> Action Bio
buildBio srcPath = cacheAction ("build" :: T.Text, srcPath) $ do
    liftIO . putStrLn $ "Rebuilding aboutme/bio: " <> srcPath
    bioContent <- readFile' srcPath
    -- load post content and metadata as JSON blob
    bioData <- mdToHTML . T.pack $ bioContent
    convert bioData

buildEducation :: FilePath -> Action Education
buildEducation srcPath = cacheAction ("build" :: T.Text, srcPath) $ do
    liftIO . putStrLn $ "Rebuilding aboutme/education: " <> srcPath
    eduContent <- readFile' srcPath
    -- load post content and metadata as JSON blob
    eduData <- mdToHTML . T.pack $ eduContent
    convert eduData

buildAboutMe :: SiteM ()
buildAboutMe = do
    outputFolder <- ask
    lift $ do
        -- Get Paths
        [bioPath] <- getDirectoryFiles "." ["site/aboutme//bio.md"]
        experiencePaths <- getDirectoryFiles "." ["site/aboutme/experience//*.md"]
        educationPaths <- getDirectoryFiles "." ["site/aboutme/education//*.md"]

        -- Build Data Structures
        bioData <- buildBio bioPath
        expsData <- forP experiencePaths buildExperience
        edusData <- forP educationPaths buildEducation
        let aboutMeData =
                AboutMe
                    { bio = bioData
                    , experience = sortBy (flip compare) expsData
                    , education = edusData
                    }
        -- Compile HTML
        aboutMeT <- compileTemplate' "site/templates/aboutme.html"
        let cvHTML = T.unpack $ substitute aboutMeT $ withSiteMeta $ toJSON aboutMeData
        writeFile' (outputFolder </> "aboutme.html") cvHTML

buildIndex :: SiteM ()
buildIndex = do
    outputFolder <- ask
    lift $ do
        indexT <- compileTemplate' "site/templates/index.html"
        let withOgType = _Object . at "ogType" ?~ String "website"
            indexHTML = T.unpack $ substitute indexT $ withOgType $ toJSON siteMeta
        writeFile' (outputFolder </> "index.html") indexHTML

-- | given a list of posts this will build a table of contents
buildTableOfContents :: [Post] -> SiteM ()
buildTableOfContents posts' = do
    outputFolder <- ask
    lift $ do
        postsT <- compileTemplate' "site/templates/posts.html"
        let postsInfo = PostsInfo{posts = sortBy (\x y -> compare (date y) (date x)) posts'}
            withUrl = _Object . at "url" ?~ String "posts"
            withOgType = _Object . at "ogType" ?~ String "articles"
            postsData = withSiteMeta . withUrl . withOgType $ toJSON postsInfo
            postsHTML = T.unpack $ substitute postsT postsData
        writeFile' (outputFolder </> "posts.html") postsHTML

-- | Find and build all posts
buildPosts :: SiteM [Post]
buildPosts = do
    pPaths <- lift $ getDirectoryFiles "." ["site/posts//*.md"]
    forP' pPaths buildPost

{- | Load a post, process metadata, write it to output, then return the post object
 Detects changes to either post content or template
-}
buildPost :: FilePath -> SiteM Post
buildPost srcPath = do
    outputFolder <- ask
    lift . cacheAction ("build" :: T.Text, srcPath) $ do
      liftIO . putStrLn $ "Rebuilding post: " <> srcPath
      postContent <- readFile' srcPath
      -- load post content and metadata as JSON blob
      postData <- mdToHTML . T.pack $ postContent
      let postUrl = T.pack . dropDirectory1 $ srcPath -<.> "html"
          withPostUrl = _Object . at "url" ?~ String postUrl
          withOgType = _Object . at "ogType" ?~ String "article"
          withPrettyDate = over (_Object . at "date" . mapped) $
            \case
              String s -> String . T.pack . formatDatePretty . T.unpack $ s
              x -> x
      -- Add additional metadata we've been able to compute
      let fullPostData = withSiteMeta . withPostUrl . withOgType $ postData
      template <- compileTemplate' "site/templates/post.html"
      writeFile' (outputFolder </> T.unpack postUrl) . T.unpack
        $ substitute template . withPrettyDate
        $ fullPostData
      convert fullPostData

-- | Copy all static files from the listed folders to their destination
copyStaticFiles :: SiteM ()
copyStaticFiles = do
    outputFolder <- ask
    lift $ do
        filepaths <-
            getDirectoryFiles
                "./site/"
                [ "images//*"
                , "css//*"
                , "js//*"
                , "fonts//*"
                ]
        void $
            forP filepaths $ \filepath ->
                copyFileChanged ("site" </> filepath) (outputFolder </> filepath)

parsedTime :: (ParseTime t, FormatTime t) => String -> t
parsedTime = parseTimeOrError True defaultTimeLocale "%Y/%m/%d"

formatDateIso :: String -> String
formatDateIso = toIsoDate . parsedTime

formatDatePretty :: String -> String
formatDatePretty = formatTime defaultTimeLocale "%b %e, %Y" . parsedTime @Day

toIsoDate :: UTCTime -> String
toIsoDate = iso8601Show

buildFeed :: [Post] -> SiteM ()
buildFeed feedPosts = do
    outputFolder <- ask
    now <- liftIO getCurrentTime
    let atomData =
            AtomData
                { title = "Jonathan Lorimer"
                , domain = "https://jonathanlorimer.dev"
                , author = "Jonathan Lorimer"
                , posts = mkAtomPost <$> feedPosts
                , currentTime = toIsoDate now
                , atomUrl = "/atom.xml"
                }
    lift $ do
        atomTempl <- compileTemplate' "site/templates/atom.xml"
        writeFile' (outputFolder </> "atom.xml") . T.unpack $ substitute atomTempl (toJSON atomData)

mkAtomPost :: Post -> Post
mkAtomPost p = p { date = formatDateIso $ date p }

buildCNAME :: SiteM ()
buildCNAME =
    ask >>= \outputFolder ->
        writeFile' (outputFolder </> "CNAME") . T.unpack $ "jonathanlorimer.dev"

{------------------------------------------------
                 Shake Build
 ------------------------------------------------}

buildRules :: SiteM ()
buildRules = do
    allPosts <- buildPosts
    buildAboutMe
    buildIndex
    buildTableOfContents allPosts
    buildFeed allPosts
    buildCNAME
    copyStaticFiles

main :: IO ()
main = do
    let shOpts = shakeOptions{shakeVerbosity = Chatty, shakeLintInside = ["\\"]}
    mOutputDir <- lookupEnv "OUTPUT_DIR"
    shakeArgsForward shOpts $ runReaderT buildRules (fromMaybe "build/" mOutputDir)
