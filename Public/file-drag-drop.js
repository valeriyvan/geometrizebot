// ## custom drag and drop input field
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
            invalidFileSize = previewContainer[i].querySelector('.invalidFileSize'),
            invalidFileType = previewContainer[i].querySelector('.invalidFileType');

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
                        };

                        // # Note: You can add the video and document file type using this code below as well.
                        // On the preview section, you must add your own custom code to make it work as you want.
                        // } else if (fileData.startsWith('data:video')) {
                        //     icon.innerHTML = '';
                        //     icon.className = '';
                        //     icon.className = 'file-drop-icon ci-video';
                        // } else {
                        //     icon.innerHTML = '';
                        //     icon.className = '';
                        //     icon.className = 'file-drop-icon ci-document';
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

            if (file && ((file.type == "image/jpeg") || (file.type == "image/png"))) {
                previewImageElement.style.display = 'block';
                previewImageElement.src = URL.createObjectURL(file)
            }
        });

        // # remove preview image
        previewContainer[i].querySelector('.remove-upload-btn').addEventListener('click', function () {
            previewImageElement.src = '';
            previewImageElement.style.display = 'none';

        });
    }

    for (var i = 0; i < dropArea.length; i++) {
        chkAllDropArea(i);
        previewImage(i);
    }
}();
