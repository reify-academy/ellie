module App.Model
    exposing
        ( Model
        , Flags
        , model
        , updateClientRevision
        , isOwnedProject
        , isSavedProject
        , isRevisionChanged
        , commitStagedCode
        , resetStagedCode
        , canCompile
        , canSave
        )

import Window exposing (Size)
import RemoteData exposing (RemoteData(..))
import Types.ApiError as ApiError exposing (ApiError)
import Types.Session as Session exposing (Session)
import Types.Revision as Revision exposing (Revision)
import Types.CompileError as CompileError exposing (CompileError)
import Types.NewPackageFlow as NewPackageFlow exposing (NewPackageFlow(..))
import Types.Notification as Notification exposing (Notification)
import App.Routing as Routing exposing (Route(..))


type alias Flags =
    { windowSize : Window.Size
    , online : Bool
    }


type alias Model =
    { session : RemoteData ApiError Session
    , serverRevision : RemoteData ApiError Revision
    , clientRevision : Revision
    , currentRoute : Route
    , compileResult : RemoteData ApiError (List CompileError)
    , stagedElmCode : String
    , stagedHtmlCode : String
    , firstCompileComplete : Bool
    , saveState : RemoteData ApiError ()
    , isOnline : Bool
    , newPackageFlow : NewPackageFlow
    , notifications : List Notification
    , notificationsOpen : Bool
    , notificationsHighlight : Bool
    , resultSplit : Float
    , resultDragging : Bool
    , editorSplit : Float
    , editorDragging : Bool
    , windowSize : Size
    }


emptyRevision : Revision
emptyRevision =
    Revision.empty


model : Flags -> Model
model flags =
    { session = NotAsked
    , serverRevision = NotAsked
    , clientRevision = emptyRevision
    , stagedElmCode = emptyRevision.elmCode
    , stagedHtmlCode = emptyRevision.htmlCode
    , currentRoute = NotFound
    , compileResult = NotAsked
    , firstCompileComplete = False
    , saveState = NotAsked
    , isOnline = flags.online
    , newPackageFlow = NotSearching
    , notifications = []
    , notificationsOpen = False
    , notificationsHighlight = False
    , resultSplit = 0.5
    , resultDragging = False
    , editorSplit = 0.5
    , editorDragging = False
    , windowSize = flags.windowSize
    }


canCompile : Model -> Bool
canCompile model =
    let
        stagedCodeChanged =
            (model.stagedElmCode /= model.clientRevision.elmCode)
                || (model.stagedHtmlCode /= model.clientRevision.htmlCode)
    in
        not (RemoteData.isLoading model.compileResult)
            && RemoteData.isSuccess model.session
            && RemoteData.isSuccess model.serverRevision
            && ((not model.firstCompileComplete) || stagedCodeChanged)
            && model.isOnline


canSave : Model -> Bool
canSave model =
    let
        stagedCodeChanged =
            (model.stagedElmCode /= model.clientRevision.elmCode)
                || (model.stagedHtmlCode /= model.clientRevision.htmlCode)
    in
        (stagedCodeChanged || isRevisionChanged model || not (isSavedProject model))
            && not (RemoteData.isLoading model.saveState)
            && model.isOnline


isRevisionChanged : Model -> Bool
isRevisionChanged model =
    model.serverRevision
        |> RemoteData.map ((/=) model.clientRevision)
        |> RemoteData.withDefault False


isSavedProject : Model -> Bool
isSavedProject model =
    model.serverRevision
        |> RemoteData.toMaybe
        |> Maybe.andThen .projectId
        |> Maybe.map (\_ -> True)
        |> Maybe.withDefault False


isOwnedProject : Model -> Bool
isOwnedProject model =
    model.serverRevision
        |> RemoteData.toMaybe
        |> Maybe.map .owned
        |> Maybe.withDefault False


updateClientRevision : (Revision -> Revision) -> Model -> Model
updateClientRevision updater model =
    { model | clientRevision = updater model.clientRevision }


commitStagedCode : Model -> Model
commitStagedCode model =
    model
        |> updateClientRevision (\r -> { r | htmlCode = model.stagedHtmlCode, elmCode = model.stagedElmCode })


resetStagedCode : Model -> Model
resetStagedCode model =
    { model
        | stagedElmCode = model.clientRevision.elmCode
        , stagedHtmlCode = model.clientRevision.htmlCode
    }
