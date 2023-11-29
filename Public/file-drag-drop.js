var generatedSvg = "";

// https://applerinquest.com/how-to-preview-the-uploaded-image-in-javascript/
var fileDropArea = function () {
    var dropArea = document.querySelectorAll('.file-drop-area');
    // a container of file drop area input field and preview image section
    var previewContainer = document.querySelectorAll('.preview-image-container');

    var chkAllDropArea = function chkAllDropArea(i) {
        let input = dropArea[i].querySelector('.file-drop-input'),
            message = dropArea[i].querySelector('.file-drop-message'),
            icon = dropArea[i].querySelector('.file-drop-icon'),
            selectButton = dropArea[i].querySelector('.file-drop-btn'),
            removeButton = dropArea[i].querySelector('.remove-upload-btn'),
            downloadSvgButton = dropArea[i].querySelector('.download-svg-btn'),
            invalidFileSize = previewContainer[i].querySelector('.invalidFileSize'),
            invalidFileType = previewContainer[i].querySelector('.invalidFileType'),
            submitFormButton = previewContainer[i].querySelector('.submit-form-button');

        message.innerHTML = "Drag and drop here to upload";

        selectButton.addEventListener('click', function () {
            input.click();
        });

        removeButton.addEventListener('click', function () {
            input.value = '';
            invalidFileSize.style.display = 'none';
            invalidFileType.style.display = 'none';
            message.innerHTML = "Drag and drop here to upload";

            // input file
            let fileDropPreview = previewContainer[i].querySelector('.file-drop-preview');
            if (fileDropPreview && fileDropPreview.querySelector("img")) {

                // remove the file drop icon
                fileDropPreview.querySelector("img").remove();
                fileDropPreview.className = "file-drop-icon";

                // add the upload icon
                const originIcon = document.createElement("i");
                originIcon.className = "fa-solid fa-cloud-arrow-up";
                icon.appendChild(originIcon);

                // remove download SVG button
                downloadSvgButton.style.display = 'none';

                // disable submit button
                submitFormButton.disabled = true;
            }

        });

        input.addEventListener('change', function () {
            // # preview image at the input file
            if (input.files && input.files[0] && ((input.files[0].type == "image/jpeg") || (input.files[0].type == "image/png"))) {
                var reader = new FileReader();

                reader.onload = function (e) {
                    var fileData = e.target.result;
                    var fileName = input.files[0].name;
                    message.innerHTML = fileName;

                    if (fileData.startsWith('data:image')) {
                        var image = new Image();
                        image.src = fileData;

                        image.onload = function () {
                            // CSS is already added in the style script
                            icon.className = 'file-drop-preview img-thumbnail rounded';
                            icon.innerHTML = '<img src="' + image.src + '" alt="' + fileName + '">';
                            submitFormButton.disabled = false;
                            downloadSvgButton.style.display = 'none';
                        };
                    }
                };

                reader.readAsDataURL(input.files[0]);
            }


            // # input field validation
            if (!input.files) { // This is VERY unlikely, browser support is near-universal
                console.error("This browser doesn't seem to support the `files` property of file inputs.");

            } else if (input.files[0]) {
                let file = input.files[0];

                // Check filesize is over 10 mb(10000000 bytes)
                if (file.size > 10000000) {
                    // show a warning message
                    invalidFileSize.style.display = "block";

                    // Check file type must be only PNG, JPEG and JPG
                } else if (!((file.type == "image/jpeg") || (file.type == "image/png"))) {
                    // show a warning message
                    invalidFileType.style.display = "block";

                } else {
                    // the file is all good

                    // hide a warning message
                    invalidFileSize.style.display = "none";
                    invalidFileType.style.display = "none";
                }
            }
        });
    };

    var previewImage = function previewImage(i) {
        // # preview image
        const uploadInput = previewContainer[i].querySelector('.file-drop-input');
        const previewImageElement = previewContainer[i].querySelector('.preview-image');

        uploadInput.addEventListener('change', function () {
            const [file] = uploadInput.files;

            //if (file && ((file.type == "image/jpeg") || (file.type == "image/png"))) {
            //    previewImageElement.style.display = 'block';
            //    previewImageElement.src = URL.createObjectURL(file)
            //}
        });

        // # remove preview image
        previewContainer[i].querySelector('.remove-upload-btn').addEventListener('click', function () {
            //previewImageElement.src = '';
            previewImageElement.style.display = 'none';

        });
    }

    for (var i = 0; i < dropArea.length; i++) {
        chkAllDropArea(i);
        previewImage(i);
    }
}();

// https://stackoverflow.com/a/26514148/942513
var Base64={_keyStr:"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",encode:function(e){var t="";var n,r,i,s,o,u,a;var f=0;e=Base64._utf8_encode(e);while(f<e.length){n=e.charCodeAt(f++);r=e.charCodeAt(f++);i=e.charCodeAt(f++);s=n>>2;o=(n&3)<<4|r>>4;u=(r&15)<<2|i>>6;a=i&63;if(isNaN(r)){u=a=64}else if(isNaN(i)){a=64}t=t+this._keyStr.charAt(s)+this._keyStr.charAt(o)+this._keyStr.charAt(u)+this._keyStr.charAt(a)}return t},decode:function(e){var t="";var n,r,i;var s,o,u,a;var f=0;e=e.replace(/[^A-Za-z0-9\+\/\=]/g,"");while(f<e.length){s=this._keyStr.indexOf(e.charAt(f++));o=this._keyStr.indexOf(e.charAt(f++));u=this._keyStr.indexOf(e.charAt(f++));a=this._keyStr.indexOf(e.charAt(f++));n=s<<2|o>>4;r=(o&15)<<4|u>>2;i=(u&3)<<6|a;t=t+String.fromCharCode(n);if(u!=64){t=t+String.fromCharCode(r)}if(a!=64){t=t+String.fromCharCode(i)}}t=Base64._utf8_decode(t);return t},_utf8_encode:function(e){e=e.replace(/\r\n/g,"\n");var t="";for(var n=0;n<e.length;n++){var r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r)}else if(r>127&&r<2048){t+=String.fromCharCode(r>>6|192);t+=String.fromCharCode(r&63|128)}else{t+=String.fromCharCode(r>>12|224);t+=String.fromCharCode(r>>6&63|128);t+=String.fromCharCode(r&63|128)}}return t},_utf8_decode:function(e){var t="";var n=0;var r=c1=c2=0;while(n<e.length){r=e.charCodeAt(n);if(r<128){t+=String.fromCharCode(r);n++}else if(r>191&&r<224){c2=e.charCodeAt(n+1);t+=String.fromCharCode((r&31)<<6|c2&63);n+=2}else{c2=e.charCodeAt(n+1);c3=e.charCodeAt(n+2);t+=String.fromCharCode((r&15)<<12|(c2&63)<<6|c3&63);n+=3}}return t}}

// https://html.form.guide/action/form-action-call-javascript-function/
function submitForm(event) {
    event.preventDefault();
    var uploadForm = document.getElementById("upload-form");
    var formData = new FormData(uploadForm);

    var dropArea = document.querySelector('.file-drop-area');
    selectButton = dropArea.querySelector('.file-drop-btn'),
    selectButton.disabled = true;
    removeButton = dropArea.querySelector('.remove-upload-btn'),
    removeButton.disabled = true;
    document.querySelector('.activity-indicator').style.display = "block";

    // https://stackoverflow.com/a/61546525/942513
    Array.from(uploadForm.elements).forEach(formElement => formElement.disabled = true);

    fetch("/ajax", {
        method: "POST",
        body: formData,
    })
    .then(response => {
        document.querySelector('.activity-indicator').style.display = "none";
        selectButton.disabled = false;
        removeButton.disabled = false;
        document.querySelector('.download-svg-btn').style.display = "inline";
        Array.from(uploadForm.elements).forEach(formElement => formElement.disabled = false);
        if (!response.ok) {
            throw new Error('network returns error');
        }
        return response.text();
    })
    .then((resp) => {
        var elements = document.getElementsByClassName('file-drop-preview img-thumbnail rounded')
        var img = '<img src="' + 'data:image/svg+xml;base64,' + Base64.encode(resp) + '" alt="' + "fileName.svg" + '">';
        elements[0].innerHTML = img;
        generatedSvg = resp;
    })
    .catch((error) => {
        // Handle error
        console.log("error ", error);
    });
}

// https://zwbetz.com/create-a-text-file-in-memory-then-download-it-on-button-click-with-vanilla-js/
const download = (filename, contents, mimeType = "image/svg+xml") => {
    const blob = new Blob([contents], { type: mimeType })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = filename
    a.click()
    a.remove()
    URL.revokeObjectURL(url)
}

const handleDownload = () => {
    const filename = "file.svg"
    const contents = generatedSvg;
    download(filename, contents)
}
//

var uploadForm = document.getElementById("upload-form");
uploadForm.addEventListener("submit", submitForm);
